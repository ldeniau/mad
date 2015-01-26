local factory, berz = require"factory", require"lib.tpsaBerz"
local rand = math.random
local printf, fprintf, mono_print = factory.printf, factory.fprintf, factory.mono_print

local M = {}  -- this module

local min, abs = math.min, math.abs

local function dummy_fct() return 0 end

-- UTILS -----------------------------------------------------------------------

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

local function identical_value(v1, v2, eps, name1, name2, val_name)
  local minV = min(v1,v2) == 0 and 1 or min(v1,v2)

  if abs((v1-v2)/minV) > eps then
    printf("%s_%s = %.18f\n%s_%s = %.18f\n",
           name1, val_name, v1, name2, val_name, v2)
    return false
  end
  return true
end

local function check_identical(t1, t2, eps, To, fct_name)
  for m=0,#To do
    local v1, v2 = t1:getCoeff(To[m]), t2:getCoeff(To[m])

    -- get the min for computing relative error
    local minV = min(v1,v2) == 0 and 1 or min(v1,v2)

    if not identical_value(v1, v2, eps, t1.name, t2.name, "coeff") then
      printf("\n mono: ")
      mono_print(To[m])
      printf("\n")
      if #To < 50 then
        t1:print()
        t2:print()
      end
      error("Coefficients differ among libraries for " .. fct_name)
    end
  end
end

-- CHECKS ----------------------------------------------------------------------

local function check_bin_with_berz(mod)
  -- factory has already been setup for {mod, nv, no}
  local funcs = {"mul", "add", "sub"}
  -- tr = t1 *op* t2;    br = b1 *op* b2;     tr == br
  local t1s, t2s, trs = {}, {}, {}
  local b1s, b2s, brs = {}, {}, {}

  for fi=1,#funcs do
    t1s[fi], t2s[fi], trs[fi] = factory.get_args(funcs[fi])
  end

  factory.setup(berz)
  for fi=1,#funcs do
    b1s[fi], b2s[fi], brs[fi] = factory.get_args(funcs[fi])
  end

  for fi=1,#funcs do
    local op_mod  = mod  [funcs[fi]]
    local op_berz = berz [funcs[fi]]
    op_mod (t1s[fi], t2s[fi], trs[fi])
    op_berz(b1s[fi], b2s[fi], brs[fi])

    check_identical(trs[fi], brs[fi], 1e-13, factory.To, funcs[fi])
    fprintf(M.file, "\n==== %s =======================\n", funcs[fi])
    factory.print_all(M.file, {t1s[fi], t2s[fi], trs[fi]})
  end

  factory.setup(mod)  -- restore original
end

local function check_subst_with_berz(mod)
  local ma, mb, lb, mc, ptrs_t, ptrs_b
  ma, mb, lb, mc, ptrs_t = factory.get_args("subst")
  mod.subst(ma, mb, lb, mc)

  factory.setup(berz)
  ma, mb, lb, mc, ptrs_b = factory.get_args("subst")

  berz.subst(ma, mb, lb, mc)

  check_identical(ptrs_t.mc[1], ptrs_b.mc[1], 1e-13, factory.To, "subst")

  factory.setup(mod)  -- restore original
end

local function check_der_with_berz(mod)
  local ma, var, mr = factory.get_args("der")
  mod.der(ma, var, mr)

  factory.setup(berz)
  local ba, _, br = factory.get_args("der")
  berz.der(ba, var, br)

  check_identical(mr, br, 1e-17, factory.To, "der")

  factory.setup(mod)  -- restore original
end

local function check_abs_with_berz(mod)
  local t, b, t_norm , b_norm , t_norm2, b_norm2, min_norm, t_pos, b_pos,
        t_cmp1, t_cmp2, b_cmp1, b_cmp2

  factory.setup(berz)
  b       = factory.full(10.1, -0.1)
  b_pos   = factory.new_instance()
  b_cmp1  = factory.full(10.1, -0.1)
  b_cmp2  = factory.full(10.1,  0.1)

  factory.setup(mod)
  t       = factory.full(10.1, -0.1)

  b_norm  = berz.abs(b)
  t_norm  = mod.abs(t)

  assert(identical_value(t_norm, b_norm, 1e-13, t.name, b.name, "norm"),
         "Different norm")


  if mod.abs2 then
    b_norm2 = berz.abs2(b)
    t_norm2 = mod.abs2(t)
    assert(identical_value(t_norm2, b_norm2, 1e-13, t.name, b.name, "norm2"),
           "Different norm2")
  end

    -- bug in TPSALib.f
--  if mod.pos then
--    t_pos = factory.new_instance()
--    mod.pos (t, t_pos)
--    berz.pos(b, b_pos)
--    check_identical(t_pos, b_pos, 1e-13, factory.To, "pos")
--  end

--  if mod.comp then
--    local t_cmp1 = factory.full(10.1, -0.1)  -- same args as for b_cmp1
--    local t_cmp2 = factory.full(10.1,  0.1)  -- same args as for b_cmp2
--    local t_cmp_val1 = mod.comp (t, t_cmp1)
--    local t_cmp_val2 = mod.comp (t, t_cmp2)
--    local b_cmp_val1 = berz.comp(b, b_cmp1)
--    local b_cmp_val2 = berz.comp(b, b_cmp2)

--    assert(identical_value(t_cmp_val1, b_cmp_val1, 1e-13, t.name, b.name, "comp"),
--           "Different comp")

--    assert(identical_value(t_cmp_val2, b_cmp_val2, 1e-13, t.name, b.name, "comp"),
--           "Different comp")
--  end
end

local function check_minv_with_berz(mod)
  local sa, ma, sc, mc, m_refs = factory.get_args("minv_raw")
  mod.minv_raw(sa, ma, sc, mc)

  factory.setup(berz)
  local sba, ba, sbc, bc, b_refs = factory.get_args("minv_raw")
  berz.minv_raw(sba, ba, sbc, bc)

  for i=1,sc do
    check_identical(m_refs.mc[i], b_refs.mc[i], 1e-4, factory.To, 'minv')
  end

  factory.setup(mod)  -- restore original
end

local function check_fun_with_berz(mod)
  local funcs = {'inv', 'sqrt', 'isrt', 'exp', 'log', 'sin', 'cos'}
  local t_in, t_out = factory.get_args("fun")
  local t_in_zero   = factory.full(0.0)  -- a0 = 0

  factory.setup(berz)
  local b_in, b_out = factory.get_args("fun")
  local b_in_zero   = factory.full(0.0)  -- a0 = 0

  for _,fun in pairs(funcs) do
    mod [fun](t_in,t_out)
    berz[fun](b_in,b_out)

    check_identical(t_in , b_in , 1e-6, factory.To, fun)
    check_identical(t_out, b_out, 1e-6, factory.To, fun)
    fprintf(M.file, "\n==== %s =======================\n", fun)
    factory.print(M.file,t_in,t_out)
  end

  for _,fun in pairs({'sirx', 'corx', 'sidx'}) do
    mod [fun](t_in_zero,t_out)
    berz[fun](b_in_zero,b_out)

    check_identical(t_in_zero, b_in_zero, 1e-6, factory.To, fun)
    check_identical(t_out    , b_out    , 1e-6, factory.To, fun)
    fprintf(M.file, "\n==== %s =======================\n", fun)
    factory.print(M.file,t_in,t_out)
  end

  factory.setup(mod)  -- restore original
end

-- CHECKING & DEBUGGING --------------------------------------------------------

function M.do_all_checks(mod, nv, no)
  -- should be called before any other function in this module
  if M.file and factory.mod ~= mod then  -- file is for another module
    M.file:close()
    M.file = nil
  end

  if not M.file then
    local filename = (mod.name or "check") .. ".out"
    M.file = io.open(filename, "w")
  end

  fprintf(M.file, "\n\n== NV= %d, NO= %d =======================", nv, no)
  factory.setup(mod,nv,no)
  check_coeff()

  if mod.name == "berz" then return end
  check_bin_with_berz(mod)
  check_subst_with_berz(mod)
  check_der_with_berz(mod)
  check_abs_with_berz(mod)
  check_fun_with_berz(mod)
  check_minv_with_berz(mod)
end

M.identical = check_identical

return M
