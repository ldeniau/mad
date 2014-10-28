local factory = require"factory"
local random = math.random

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

local function check_coeff(mod, nv, no)
  local t, To = factory.setup(mod, 'getm', nv, no)

  -- initial state
  local v
  for m=0,#To do
    v = t:getm(To[m])
    if v ~= 0 then error ("Initial coefficients differ from 0: i=" .. m) end
  end

  -- setm and getm consistency
  local c = {}
  for m=0,#To do
    c[m] = random(1, 2)
    t:setm(To[m], c[m])
  end
  for m=0,#To do
    v = t:getm(To[m])
    if v ~= c[m] then error ("Inconsistent coefficients setup: i=" .. m) end
  end

  -- setCoeff and getm consistency
  local tm, To_m = factory.setup(mod, 'getm'    , nv, no)
  local tc, To_c = factory.setup(mod, 'getCoeff', nv, no)
  if #To_m ~= #To_c then error("Inconsistent To setup") end
  for m=0,#To_c do
    c[m] = random(1, 2)
    t:setCoeff(To_c[m], c[m])
  end
  for m=0,#To_m do
    v = t:getm(To_m[m])
    if v ~= c[m] then error ("Inconsistent coefficients setup: i=" .. m) end
  end

  -- setm and getCoeff consistency
  local tm, To_m = factory.setup(mod, 'getm'    , nv, no)
  local tc, To_c = factory.setup(mod, 'getCoeff', nv, no)
  if #To_m ~= #To_c then error("Inconsistent To setup") end
  for m=0,#To_m do
    c[m] = random(1, 2)
    t:setm(To_m[m], c[m])
  end
  for m=0,#To_c do
    v = t:getCoeff(To_m[m])
    if v ~= c[m] then error ("Inconsistent coefficients setup: i=" .. m) end
  end
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
  M.mod, M.nv, M.no = mod, nv, no

  if not M.file then
    local filename = (mod.name or "check") .. ".out"
    M.file = io.open(filename, "w")
  end

  factory.fprintf(M.file, "\n\n== NV= %d, NO= %d =======================", nv, no)
  check_coeff(mod, nv, no)
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
