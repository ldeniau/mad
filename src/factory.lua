local ffi = require"ffi"

local M = {}  -- this module

-- HELPERS ---------------------------------------------------------------------

local function mono_val(l, n)
  local a = {}
  for i=1,l do a[i] = n end
  return a
end

local function mono_add(a,b)
  local c = {}
  for i=1,#a do c[i] = a[i]+b[i] end
  return c
end

local function mono_sum(a)
  local s = 0
  for i=1,#a do s = s + a[i] end
  return s
end

local function melem_leq(a,b)
  for i=1,#a do
    if a[i] > b[i] then return false end
  end
  return true
end

local function mono_isvalid(m, a, o)
  return mono_sum(m) <= o and melem_leq(m,a)
end

local function mono_print(m, file)
  file = file or io.output()
  for mi=1,#m do
    fprintf(file, "%d ", m[mi])
  end
end

-- LOCALS ----------------------------------------------------------------------

local function initMons(nv)
  local t = { ps={ [0]=0, [1]=1 }, pe={ [0]=0, [1]=nv } }

  t[0] = mono_val(nv, 0)
  for i=1,nv do
    t[i] = mono_val(nv, 0)
    t[i][i] = 1
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
        local m = mono_add(t[i], t[j])
        if mono_isvalid(m, a, no) then
          t[#t+1] = m
        end
        j = j+1
      until m[i] > a[i] or m[i] >= ord

    end
    t.ps[ord]   = j
    t.pe[ord-1] = j-1
  end
  return t
end

local function make_ffi_To(mono_t, To)
  local To_ffi = { ps=To.ps, pe=To.pe }
  for i=0,#To do To_ffi[i] = mono_t(#To[i], To[i]) end
  return To_ffi
end


local function setup_peek(mod, nv, no)
  local To = M.To
  if mod.mono_t then  -- use cdata for To
    To = make_ffi_To(mod.mono_t, To)
  end

  return mod.init(mono_val(nv,no), no), To
end

local function setup_bin_op(mod, nv, no)
  local t = mod.init(mono_val(nv,no), no)
  M.fill_ord1(t)
  M.fill_full(t)
end


function M.setup(mod, fct_name, nv, no)
  if not M.nv or not M.no or M.nv ~= nv or M.no ~= no then
    M.nv, M.no, M.To = nv, no, table_by_ords(nv, no)
  end

  if     fct_name == "setm"     or fct_name == "getm"     then
    return setup_peek(mod, nv, no)

  elseif fct_name == "setCoeff" or fct_name == "getCoeff" then
    return mod.init(mono_val(nv,no), no), M.To

  elseif fct_name == "mul"      or fct_name == "__mul"    or
         fct_name == "add"      or fct_name == "sub"      then
    return setup_bin_op(mod, nv, no)

  elseif fct_name == "compose" then
    return setup_compose(mod, nv, no)

  else
    error("Cannot setup function " .. fct_name)
  end
end

-- EXPORTED UTILS --------------------------------------------------------------
local function fprintf(f, s, ...)  -- TODO: put this somewhere and import it
  f:write(s:format(...))
end

M.mono_val = mono_val
M.fprintf  = fprintf

function M.fill_ord1(t, nv, startVal, inc)
  if not startVal then startVal = 1.1 end
  if not inc      then inc      = 0.1 end
  local m = mono_val(nv, 0)
  t:setCoeff(m, startVal)
  for i=1,nv do
    m[i] = 1
    startVal = startVal + inc
    t:setCoeff(m, startVal)
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
    fprintf(io.output(), "\n%d lines read from %s.\n", l, filename)
  end
  f:close()
  return NV, NO, NL
end

return M