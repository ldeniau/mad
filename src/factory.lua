local ffi = require"ffi"

local M = {}  -- this module

-- HELPERS ---------------------------------------------------------------------

local function mono_val(l, n)
  local a, rand = {}, math.random

  if   n then for i=1,l do a[i] = n          end
  else        for i=1,l do a[i] = 1 + rand() end
  end

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

local function make_To_ffi(mono_t, To)
  if not mono_t then return To end

  local To_ffi = { ps=To.ps, pe=To.pe }
  for i=0,#To do To_ffi[i] = mono_t(#To[i], To[i]) end
  return To_ffi
end

local function setup_bin_op(mod, nv, no)
  local t = mod.init(mono_val(nv,no), no)
  M.fill_ord1(t)
  M.fill_full(t)
end

function M.new_instance()
  M.t = M.mod.init(mono_val(M.nv,M.no), M.no)
  return M.t
end

function M.get_params(fct_name)
  local val = 4.3
  local params = { -- use anonymous functions to avoid unpack which is not compiled
    getm     = function() return M.t, M.To_ffi,      M.nv end,
    getCoeff = function() return M.t, M.To                end,
    setm     = function() return M.t, M.To_ffi, val, M.nv end,
    setCoeff = function() return M.t, M.To    , val       end,
    generic  = function() return M.t, M.To                end
  }
  return params[fct_name]()
end

-- args = table with named or positional arguments:
--   mod      or args[1] = the loaded tpsa module
--   nv       or args[2] = NV parameter for the mod
--   no       or args[3] = NO parameter for the mod
--   need_ffi or args[4] = [opt] 0 to disable reconstruction of To_ffi (1 by default)
function M.setup(args)
  -- process arguments
  local mod, nv, no = args[1] or args.mod, args[2] or args.nv, args[3] or args.no
  local need_ffi = args[4] or args.need_ffi or true
  if not M.mod and not nv and not no then
    error("Cannot setup factory: not enough args and no previous state")
  end

  -- save / update state
  local state_changed = false
  if nv and no and (nv ~= M.nv or no ~= M.no) then
    M.nv, M.no, M.To, state_changed = nv, no, table_by_ords(nv, no), true
  end
  if mod and mod ~= M.mod then
    M.mod, state_changed = mod, true
  end
  if state_changed and need_ffi then
    M.To_ffi = make_To_ffi(mod.mono_t, M.To)
  end

  M.new_instance()
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
