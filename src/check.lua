local factory = require"factory"
local rand = math.random
local printf, fprintf, mono_print = factory.printf, factory.fprintf, factory.mono_print

local M = {}  -- this module

local min, abs = math.min, math.abs

local function prepare_check(vars, no)
  local mod, To = M.mod, M.To
  if not vars or not no then
    vars, no = M.vars, M.no
  elseif vars ~= M.vars or no ~= M.no then
    To = table_by_ords(#vars, no)
  end

  local berz = require"lib.tpsaBerz"
--  local t =  mod(mono_val(#vars,no), no, mono_val(2,0), 12)
  local t =  mod.init(mono_val(#vars,no), no)
  local b = berz.init(vars, no)

  M.fill_ord1(b, #vars)
  M.fill_full(b, no)
  M.fill_ord1(t, #vars)
  M.fill_full(t, no)

  return t, b, To
end

local function dummy_fct() return 0 end

local function check_coeff_consistency(fset_name, fget_name, in_vals, err_code)
  local err_fmt = "Error %d: inconsistent coefficients at %d (%d should have been %d)"

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



local function check_with_berz(mod, nv, no)
  -- factory has already been setup for {mod, nv, no}
  local funcs = {"mul"}
  -- tr = t1 *op* t2;    br = b1 *op* b2;     tr == br
  local t1s, t2s, trs = {}, {}, {}
  local b1s, b2s, brs = {}, {}, {}

  for f=1,#funcs do
--    t1s[f] = factory.setup
  end

  local berz = require"lib.tpsaBerz"
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
--  check_with_berz(mod, nv, no)
end

function M.tear_down()
  M.file:close()
end

function M.same_coeff(t1, t2, eps, To)
  for m=0,#To do
    local vt, vb = t1:getCoeff(To[m]), t2:getCoeff(To[m])

    -- get the min for computing relative error
    local minV = min(vb,vt) == 0 and 1 or min(vb,vt)

    if abs((vb-vt)/minV) > eps then
      fprintf(io.output(), "\n mono: ")
      mono_print(To[m])
      fprintf(io.output(), "  v%s = %s vBerz = %f (eps = %f)\n",
              M.mod.name, vt, vb, eps)
      t1:print()
      t2:print()
      error("Coefficients differ among libraries")
    end
  end
end

function M.with_berz(eps, vars, no)
  -- cross checks a full tpsa of (nv, no) with a full berz tpsa
  -- if nv, no are not specified then the ones from setup are used

  local mod, t, b, To = M.mod, prepare_check(vars, no)
  eps = eps or 1e-3
  M.same_coeff(t, b, eps, To)
end

function M.print(t)
  local f, To = M.file, M.To

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
