local factory = require"factory"
local rand = math.random
local printf, fprintf, mono_print = factory.printf, factory.fprintf, factory.mono_print

local M = {}  -- this module

local min, abs = math.min, math.abs

local function dummy_fct() return 0 end

local function check_coeff_consistency(fset_name, fget_name, in_vals, err_code)
  local err_fmt = "Error %d: inconsistent coefficients at %d (%f should have been %f)"

  local t, To_set, To_get, l_set, l_get, _

  t = factory.new_instance()
  To_set, _, l_set = factory.get_args(fset_name or "generic")
  To_get,    l_get = factory.get_args(fget_name)

  if #To_set ~= #To_get  then error("Inconsistent factory setup")  end
  if #To_get ~= #in_vals then error("Incorrect in_vals")  end

  local fset = fset_name and t[fset_name] or dummy_fct
  local fget = t[fget_name] or error("Incorrect get function: " .. fget_name)

  local out_vals = {}
  for m=0,#To_set  do               fset(t, To_set[m], in_vals[m], l_set) end
  for m=0,#To_get  do out_vals[m] = fget(t, To_get[m],             l_get) end
  for m=0,#in_vals do
    if in_vals[m] ~= out_vals[m] then
      error(string.format(err_fmt, err_code, m, out_vals[m], in_vals[m]))
    end
  end
end

local function check_coeff()
  local in_vals

  in_vals = factory.mono_val(#factory.To, 0)  -- initially all should be 0
  in_vals[0] = 0
  check_coeff_consistency(nil,        "getm"    , in_vals, -1)
  check_coeff_consistency(nil,        "getCoeff", in_vals, -2)

  in_vals = factory.mono_val(#factory.To)     -- randoms
  in_vals[0] = 1 + rand()
  check_coeff_consistency("setCoeff", "getCoeff", in_vals,  0)
  check_coeff_consistency("setCoeff", "getm"    , in_vals,  1)
  check_coeff_consistency("setm"    , "getCoeff", in_vals,  2)
  check_coeff_consistency("setm"    , "getm"    , in_vals,  3)
end

local function check_identical(t1, t2, eps, To, fct_name)
  for m=0,#To do
    local v1, v2 = t1:getCoeff(To[m]), t2:getCoeff(To[m])

    -- get the min for computing relative error
    local minV = min(v1,v2) == 0 and 1 or min(v1,v2)

    if abs((v1-v2)/minV) > eps then
      printf("\n mono: ")
      mono_print(To[m])
      printf("  val_%s = %s val_%s = %f (eps = %f)\n",
             t1.name, v1, t2.name, v2, eps)
      t1:print()
      t2:print()
      error("Coefficients differ among libraries for " .. fct_name)
    end
  end
end


local function check_bin_with_berz(mod)
  -- factory has already been setup for {mod, nv, no}
  local funcs = {"mul", "add", "sub"}
  -- tr = t1 *op* t2;    br = b1 *op* b2;     tr == br
  local t1s, t2s, trs = {}, {}, {}
  local b1s, b2s, brs = {}, {}, {}

  for fi=1,#funcs do
    fprintf(M.file, "\n== %s =======================\n", funcs[fi])
    t1s[fi], t2s[fi], trs[fi] = factory.get_args(funcs[fi])
    M.print_all(t1s[fi], t2s[fi])  -- print input
  end

  local berz = require"lib.tpsaBerz"
  factory.setup{ mod=berz, need_ffi=0 }
  for fi=1,#funcs do
    b1s[fi], b2s[fi], brs[fi] = factory.get_args(funcs[fi])
  end

  for fi=1,#funcs do
    local op_mod  = mod  [funcs[fi]]
    local op_berz = berz [funcs[fi]]
    op_mod (t1s[fi], t2s[fi], trs[fi])
    op_berz(b1s[fi], b2s[fi], brs[fi])

    check_identical(trs[fi], brs[fi], 0.001, factory.To, funcs[fi])
    M.print(trs[fi])                -- print output
  end

  factory.setup{ mod=mod, need_ffi=0 }  -- set it back
end

local function check_subst_with_berz(mod)
  local ma, mb, lb, mc, ptrs_t, ptrs_b
  ma, mb, lb, mc, ptrs_t = factory.get_args("subst")
  mod.subst(ma, mb, lb, mc)

  local berz = require"lib.tpsaBerz"
  factory.setup{ mod=berz }
  ma, mb, lb, mc, ptrs_b = factory.get_args("subst")

  berz.subst(ma, mb, lb, mc)

  check_identical(ptrs_t.mc[1], ptrs_b.mc[1], 0.001, factory.To, "subst")

  factory.setup{ mod=mod }  -- restore mod
end

local function check_der_with_berz(mod)
  local ma, var, mr = factory.get_args("der")
  mod.der(ma, var, mr)

  local berz = require"lib.tpsaBerz"
  factory.setup{ mod=berz }
  local ba, _, br = factory.get_args("der")
  berz.der(ba, var, br)

  check_identical(mr, br, 0.0001, factory.To, "der")

  factory.setup{ mod=mod }   -- restore mod
end

-- CHECKING & DEBUGGING --------------------------------------------------------

function M.do_all_checks(mod, nv, no)
  -- should be called before any other function in this module
  if M.file and M.mod ~= mod then  -- file is for another module
    M.file:close()
    M.file = nil
  end

  if not M.file then
    local filename = (mod.name or "check") .. ".out"
    M.file = io.open(filename, "w")
  end

  fprintf(M.file, "\n\n== NV= %d, NO= %d =======================", nv, no)
  factory.setup{ mod=mod, nv=nv, no=no }
  check_coeff()

  if mod.name == "berz" then return end
  check_bin_with_berz(mod)
--  check_subst_with_berz(mod)
  check_der_with_berz(mod)
end

M.identical = check_identical

function M.print(t)
  local f, To = M.file, factory.To

  fprintf(f, "\nCOEFFICIENT                \tEXPONENTS\n")

  for m=0,#To do
    local v = t:getCoeff(To[m])
    if v ~= 0 then
      fprintf(f, "%20.10E\t", v)
      mono_print(To[m], f)
      fprintf(f, "\n")
    end
  end
end

function M.print_all(...)
  local arg = {...}
  for i=1,#arg do M.print(arg[i]) end
end


return M
