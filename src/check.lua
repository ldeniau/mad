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
  check_coeff_consistency(nil,    "getm", in_vals, -1)
  check_coeff_consistency(nil,    "get" , in_vals, -2)

  in_vals = factory.mono_val(#factory.To)     -- randoms
  in_vals[0] = 1 + rand()
  check_coeff_consistency("set" , "get" , in_vals,  0)
  check_coeff_consistency("set" , "getm", in_vals,  1)
  check_coeff_consistency("setm", "get" , in_vals,  2)
  check_coeff_consistency("setm", "getm", in_vals,  3)
end

local function identical_value(v1, v2, eps, name1, name2, val_name, abs_or_rel)
  abs_or_rel = abs_or_rel or "relative"  -- check relative error by default
  local minV = min(v1,v2) == 0 and 1 or min(v1,v2)

  local err = 0
  if     abs_or_rel == 'relative' then err = abs((v1-v2)/minV)
  elseif abs_or_rel == 'absolute' then err = abs(v1-v2)
  end

  if err > eps then
    printf("%s_%s = %.18e\n%s_%s = %.18e\n%s_err = %e\n",
           name1, val_name, v1, name2, val_name, v2, abs_or_rel, err)
    return false
  end
  return true
end

local function check_identical(t1, t2, eps, To, fct_name, abs_or_rel)
  for m=0,#To do
    local v1, v2 = t1:get(To[m]), t2:get(To[m])

    if not identical_value(v1, v2, eps, t1.name, t2.name, "coeff", abs_or_rel) then
      printf("\n mono: ")
      mono_print(To[m])
      printf("\n")
      if #To < 30 then
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
--  local funcs = {[0]="div", "mul", "add", "sub"}
  local funcs = {[0]="div", "mul"}
  local errs  = {           1e-14,   0  ,   0  }
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

    check_identical(trs[fi], brs[fi], errs[fi], factory.To, funcs[fi], "relative")

    fprintf(M.mod_file , "\n==== %s =======================\n", funcs[fi])
    fprintf(M.berz_file, "\n==== %s =======================\n", funcs[fi])
    factory.print_all(M.mod_file , {t1s[fi], t2s[fi], trs[fi]})
    factory.print_all(M.berz_file, {b1s[fi], b2s[fi], brs[fi]})
  end

--  -- treat `div` separately because it's error scales with order
--  mod [funcs[0]](t1s[0], t2s[0], trs[0])
--  berz[funcs[0]](b1s[0], b2s[0], brs[0])
--  check_identical(trs[0], brs[0], 1e-1 ^ (16-factory.no), factory.To, funcs[0])
--  fprintf(M.mod_file , "\n==== %s =======================\n", funcs[0])
--  fprintf(M.berz_file, "\n==== %s =======================\n", funcs[0])
--  factory.print_all(M.mod_file , {t1s[0], t2s[0], trs[0]})
--  factory.print_all(M.berz_file, {b1s[0], b2s[0], brs[0]})

  factory.setup(mod)  -- restore original
end

local function check_compose_with_berz(mod)
  local sa, ma, sb, mb, sc, mc, ptrs_t, ptrs_b
  sa, ma, sb, mb, sc, mc, ptrs_t = factory.get_args("compose_raw")
  mod.compose_raw(sa, ma, sb, mb, sc, mc)

  factory.setup(berz)
  sa, ma, sb, mb, sc, mc, ptrs_b = factory.get_args("compose_raw")
  berz.compose_raw(sa, ma, sb, mb, sc, mc)

  fprintf(M.mod_file , "\n==== COMPOSE_RAW OUT =======================\n")
  fprintf(M.berz_file, "\n==== COMPOSE_RAW OUT =======================\n")
  factory.print_all(M.mod_file , ptrs_t.mc)
  factory.print_all(M.berz_file, ptrs_b.mc)
  for i=1,factory.nv do
    check_identical(ptrs_t.ma[i], ptrs_b.ma[i], 1e-17, factory.To, "compose_raw input", "absolute")
    check_identical(ptrs_t.mc[i], ptrs_b.mc[i], 1e-5, factory.To, "compose_raw")
  end

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

local function check_poisson_with_berz(mod)
  local ma, mb, mr, n = factory.get_args("poisson")
  mod.poisson(ma, mb, mr, n)

  factory.setup(berz)
  local ba, bb, br, _ = factory.get_args("poisson")
  berz.poisson(ba, bb, br, n)

  check_identical(mr, br, 1e-1 ^ (16-factory.no), factory.To, "poisson","absolute")

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
    check_identical(m_refs.ma[i], b_refs.ma[i], 1e-17, factory.To, 'minv_input')
    check_identical(m_refs.mc[i], b_refs.mc[i], 1e-1 ^ (14-factory.no), factory.To, 'minv')
  end

  -- partial inversion
  local sel_rows = require"ffi".new("int[?]", sc)
  for i=0,sc-1 do sel_rows[i] = i % 2 end
  mod.pminv_raw(sa,ma,sc,mc,sel_rows)
  berz.pminv_raw(sba,ba,sbc,bc,sel_rows)

  for i=1,sc do
    check_identical(m_refs.mc[i], b_refs.mc[i], 1e-1 ^ (14-factory.no), factory.To, 'pminv')
  end

  factory.setup(mod)  -- restore original
end


local function check_set_of_fun(func_names, mod, t_in, t_out, b_in, b_out)
  for _,fun in pairs(func_names) do
    mod [fun](t_in,t_out)
    berz[fun](b_in,b_out)

--    check_identical(t_in , b_in , 1e-6, factory.To, fun, 'absolute')
--    check_identical(t_out, b_out, 1e-6, factory.To, fun, 'absolute')
    check_identical(t_in , b_in , 1e-6, factory.To, fun, 'relative')
    check_identical(t_out, b_out, 1e-6, factory.To, fun, 'relative')

    fprintf(M.mod_file , "\n==== %s =======================\n", fun)
    fprintf(M.berz_file, "\n==== %s =======================\n", fun)
    factory.print_all(M.mod_file , {t_in, t_out})
    factory.print_all(M.berz_file, {b_in, b_out})
  end
end

local function check_fun_with_berz(mod)
  local t_in, t_out = factory.get_args("fun")
  local t_in_zero   = factory.full(0.0)  -- a0 = 0

  factory.setup(berz)
  local b_in, b_out = factory.get_args("fun")
  local b_in_zero   = factory.full(0.0)  -- a0 = 0

  local funcs = {'inv', 'sqrt', 'isrt', 'exp', 'log', 'sin', 'cos'}
  check_set_of_fun(funcs,mod,t_in,t_out,b_in,b_out)

  funcs = {'sirx', 'corx', 'sidx'}
  check_set_of_fun(funcs,mod,t_in_zero,t_out,b_in_zero,b_out)

  if factory.no <= 5 then
    funcs = {'tan' , 'cot', 'asin', 'acos', 'atan', 'acot', 'sinh', 'cosh',
             'tanh', 'coth', 'asinh', 'atanh', 'erf'}
    check_set_of_fun(funcs,mod,t_in,t_out,b_in,b_out)

    funcs = {'acosh', 'acoth'}
    t_in:set(factory.To[0], 1.1)
    b_in:set(factory.To[0], 1.1)
    check_set_of_fun(funcs,mod,t_in,t_out,b_in,b_out)
  end

  factory.setup(mod)  -- restore original
end

-- EXPORTED FUNCTIONS ----------------------------------------------------------

-- should be called before any other function in this module
function M.do_all_checks(mod, nv, no)
  if M.mod_file and factory.mod ~= mod then  -- file is for another module
    M.mod_file:close()
    M.mod_file = nil
  end

  if not M.mod_file then
    local filename = (mod.name or "check") .. ".out"
    M.mod_file  = io.open(filename, "w")
    M.berz_file = io.open("berz.out", "w")
  end

  fprintf(M.mod_file , "\n\n== NV= %d, NO= %d =======================", nv, no)
  fprintf(M.berz_file, "\n\n== NV= %d, NO= %d =======================", nv, no)
  factory.setup(mod,nv,no)
  if mod.name == "mapClass" then return end

--  check_coeff()

  if mod.name == "berz" then return end
  check_bin_with_berz(mod)

  check_compose_with_berz(mod)
--  check_der_with_berz(mod)
--  check_abs_with_berz(mod)

--  if mod.name == "yang" then return end

--  check_fun_with_berz(mod)
--  check_poisson_with_berz(mod)
--  check_minv_with_berz(mod)
end

M.identical = check_identical

return M
