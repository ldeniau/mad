local factory = require"factory"
local rand = math.random

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

local function check_coeff_consistency(mod, in_vals, fset_name, fget_name, err_code)
  local fset = fset_name and mod[fset_name] or dummy_fct
  local fget = mod[fget_name] or error("Incorrect get function: " .. fget_name)
  local err_fmt = "Error %d: inconsistent coefficients at %d (%d should have been %d)"
  local t, To_set, To_get, _

  t, To_set = factory.setup{ fct_name=fset_name }
  _, To_get = factory.setup{ fct_name=fget_name }
  if #To_set ~= #To_get  then error("Inconsistent factory setup")    end
  if #To_set ~= #in_vals then error("Inconsistent consistency call") end

  local out_vals = {}
  for m=0,#To_set  do               fset(t, To_set[m], in_vals[m]) end
  for m=0,#To_get  do out_vals[m] = fget(t, To_get[m])             end
  for m=0,#in_vals do
    if in_vals[m] ~= out_vals[m] then
      error(err_fmt, err_code, m, out_vals[m], in_vals[m])
    end
  end
end

local function get_consistency_fct(state, mod)
  local nc, vals = #factory.To

  if state == "initial" then
    vals = factory.mono_val(nc, 0)
    vals[0] = 0
    return  function (fget_name, err_code)
              check_coeff_consistency(mod, vals,       nil, fget_name, err_code)
            end
  else
    vals = factory.mono_val(nc)  -- with randoms
    vals[0] = 1 + rand()
    return  function (fset_name, fget_name, err_code)
              check_coeff_consistency(mod, vals, fset_name, fget_name, err_code)
            end
  end
end

local function check_coeff(mod)
  local check_fct = get_consistency_fct("initial", mod)
  check_fct(            "getm"    , -1)
  check_fct(            "getCoeff", -2)

  check_fct = get_consistency_fct("rest", mod)
  check_fct("setCoeff", "getCoeff",  0)
  check_fct("setCoeff", "getm"    ,  1)
  check_fct("setm"    , "getCoeff",  2)
  check_fct("setm"    , "getm"    ,  3)
end



local function check_with_berz(mod, nv, no)

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

  factory.fprintf(M.file, "\n\n== NV= %d, NO= %d =======================", nv, no)
  factory.setup{ mod=mod, nv=nv, no=no }
  check_coeff(mod, #factory.To + 1)
  check_with_berz(mod, nv, no)
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
