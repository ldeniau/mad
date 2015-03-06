local M = {}
local ffi = require"ffi"

local function fprintf(f, s, ...)  -- TODO: put this somewhere and import it
  f:write(s:format(...))
end

local min, abs = math.min, math.abs

-- HELPERS ---------------------------------------------------------------------

local function mono_val(l, n)
  return M.mono_t(l, n)
end

local function mono_cpy(l, m)
  local r = mono_val(l,0)
  for i=0,l-1 do r[i] = m[i] end
  return r
end

local function mono_add(l,a,b)
  local c = mono_val(l,0)
  for i=0,l-1 do c[i] = a[i]+b[i] end
  return c
end

local function mono_sum(l,a)
  local s = 0
  for i=0,l-1 do s = s + a[i] end
  return s
end

local function melem_leq(l,a,b)
  for i=0,l-1 do
    if a[i] > b[i] then return false end
  end
  return true
end

local function mono_isvalid(l, m, a, o)
  return mono_sum(l, m) <= o and melem_leq(l, m,a)
end

local function mono_print(l, m, file)
  file = file or io.output()
  for mi=0,l-1 do
    fprintf(file, "%d ", m[mi])
  end
end

-- LOCALS ----------------------------------------------------------------------

local function initMons(nv)
  local t = { ps={ [0]=0, [1]=1 }, pe={ [0]=0, [1]=nv } }

  t[0] = mono_val(nv, 0)
  for i=1,nv do
    t[i] = mono_val(nv, 0)
    t[i][i-1] = 1
  end

  return t
end

local function table_by_ords(nv, no)
  local t, a = initMons(nv), mono_val(nv, no)

  local j
  for ord=2,no do
    for i=1,nv do
      j = t.ps[ord-1]

      repeat
        local m = mono_add(nv,t[i], t[j])
        if mono_isvalid(nv, m, a, no) then
          t[#t+1] = m
        end
        j = j+1
      until m[i-1] > a[i-1] or m[i-1] >= ord

    end
    t.ps[ord]   = j
    t.pe[ord-1] = j-1
  end
  return t
end

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


-- EXPORTED UTILS --------------------------------------------------------------

M.mono_val   = mono_val
M.mono_cpy   = mono_cpy
M.mono_print = mono_print

function M.fill_ord1(t, nv, startVal, inc)
  if not startVal then startVal = 1.1 end
  if not inc      then inc      = 0.1 end
  local m = mono_val(nv, 0)
  t:set(m, startVal)
  for i=0,nv-1 do
    m[i] = 1
    startVal = startVal + inc
    t:set(m, startVal)
    m[i] = 0
  end
end

function M.fill_full(t, no)
  -- t:pow(no)
  local b, r, floor = t:cpy(), t:new(), math.floor
  r:setConst(1)

  while no > 0 do
    if no%2==1 then
      r.mul(r, b, t)
      r, t = t, r
      no = no - 1
    end
    b.mul(b, b, t)
    b, t = t, b
    no = no/2
  end
--  r:print()
  r:cpy(t)
end

-- read benchmark input parameters: NV, NO, NL
function M.read_params(filename)
  local f = io.open(filename, "r")
  local NV, NO, NL, l = {}, {}, {}, 1

  if not f then
    error("Params file not found: " .. filename)
  else
    while true do
      local nv, no, nl, ts = f:read("*number", "*number", "*number", "*number")
      if not (nv and no and nl) then break end
      assert(nv and no and nl)
      NV[l], NO[l], NL[l] = nv, no, nl
      l = l + 1
    end
    fprintf(io.output(), "%d lines read from %s.\n", l, filename)
  end
  f:close()
  return NV, NO, NL
end


-- CHECKING & DEBUGGING --------------------------------------------------------

function M.setup(mod, vars, no, filename)
  M.mod, M.vars, M.no, M.mono_t = mod, vars, no, mod.mono_t
  if not filename then filename = (mod.name or "check") .. ".out" end
  if not M.file then
    M.file = io.open(filename, "w")
  end
  M.To = table_by_ords(#vars, no)
  fprintf(M.file, "\n\n=NV= %d, NO= %d =======================", #vars, no)
end

function M.tear_down()
  M.file:close()
end

function M.same_coeff(t1, t2, eps, To)
  for m=0,#To do
    local vt, vb = t1:get(To[m]), t2:get(To[m])

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
    local v = t:get(To[m])
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
