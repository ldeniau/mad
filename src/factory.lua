local ffi = require"ffi"

local M = {}  -- this module

-- HELPERS ---------------------------------------------------------------------
local function fprintf(f, s, ...)
  f:write(s:format(...))
end


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
    t.ps[ord] = j
    t.pe[ord] = #t
  end
  return t
end

local function make_To_ffi(mono_t, To)
  if not mono_t then return To end

  local To_ffi = { ps=To.ps, pe=To.pe }
  for i=0,#To do To_ffi[i] = mono_t(#To[i], To[i]) end
  return To_ffi
end

-- ARGUMENTS BUILD -------------------------------------------------------------
-- use functions return to avoid unpack which is not compiled

local function args_bin_op()
  return M.full(), M.full(), M.new_instance()
end

-- --- SUBST -------------------------------------------------------------------

local function args_subst_tpsa(t, nv, refs, size_a)
  ffi.cdef("typedef struct tpsa T")
  local tpsa_carr, tpsa_arr  = ffi.typeof("const T* [?]"), ffi.typeof("T* [?]")

  local cma, cmb, cmc = tpsa_carr(size_a), tpsa_carr(nv), tpsa_arr(size_a)
  for i=1,size_a do
    refs.ma[i], refs.mc[i] = t:cpy()   , t:new()
    cma[i-1]  , cmc[i-1]   = refs.ma[i], refs.mc[i]
  end
  for i=1,nv do
    refs.mb[i] = t:cpy()
    cmb[i-1]   = refs.mb[i]
  end

  if size_a == 1 then return cma, cmb, nv, cmc, refs end
  return size_a, cma, nv, cmb, size_a, cmc, refs
end

local function args_subst_berz(t, nv, refs, size_a)
  local intArr = ffi.typeof("int [?]")

  local cma, cmb, cmc = intArr(size_a), intArr(nv), intArr(size_a)
  for i=1,size_a do
    refs.ma[i], refs.mc[i] = t:cpy()          , t:new()
    cma[i-1]  , cmc[i-1]   = refs.ma[i].idx[0], refs.mc[i].idx[0]
  end
  for i=1,nv do
    refs.mb[i] = t:cpy()
    cmb[i-1]   = refs.mb[i].idx[0]
  end
  t:destroy()
  if size_a == 1 then return cma, cmb, intArr(1, {nv}), cmc, refs end
  return intArr(1, size_a), cma, intArr(1, nv), cmb, intArr(1, size_a), cma, refs

end

local function args_subst_yang(t, nv, refs, size_a)
  if size_a ~= 1 then error("No compose Yang. Use subst") end
  local uintArr = ffi.typeof("unsigned int[?]")

  local cma, cmb, cmc = uintArr(1), uintArr(nv), uintArr(1)
  refs.ma[1], refs.mc[1] = t                , t:new()
  cma[0]    , cmc[0]     = refs.ma[1].idx[0], refs.mc[1].idx[0]
  for i=1,nv do
    refs.mb[i] = t:cpy()
    cmb[i-1]   = refs.mb[i].idx[0]
  end
  return cma, cmb, uintArr(1, {nv}), cmc, refs
end

local function args_subst(size_a)
  local refs = { ma={}, mb={}, mc={} }  -- save some references to avoid GC
  local args = {
    tpsa = args_subst_tpsa,
    berz = args_subst_berz,
    yang = args_subst_yang,
  }
  return args[M.mod.name](M.full(), M.nv, refs, size_a or 1)
end

local function args_compose()
  return args_subst(M.nv)
end


--------------------------------------------------------------------------------

-- INTERFACE -------------------------------------------------------------------

function M.new_instance()
  return M.t:new()
end

function M.get_args(fct_name)
  local val = 4.3

  local args = {
    getm     = function() return M.To_ffi,      M.nv end,
    getCoeff = function() return M.To                end,
    setm     = function() return M.To_ffi, val, M.nv end,
    setCoeff = function() return M.To    , val       end,

    der      = function() return M.full(), 1, M.new_instance() end,
    mul      = args_bin_op,
    add      = args_bin_op,
    sub      = args_bin_op,
    subst    = args_subst,
    compose_raw = args_compose,
    generic  = function() return M.To                end
  }
  return args[fct_name]()
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
  if state_changed then
    M.t = M.mod.init(mono_val(M.nv,M.no), M.no)
    if need_ffi ~= 0 then M.To_ffi = make_To_ffi(mod.mono_t, M.To) end
  end

end

-- EXPORTED UTILS --------------------------------------------------------------
M.mono_val   = mono_val
M.mono_print = mono_print
M.fprintf    = fprintf
M.printf     = function (...) fprintf(io.output(), ...) end

-- returns a tpsa having only orders `ord` filled
function M.ord(ord, startVal, inc)
  -- process params
  if not startVal then startVal = 1.1 end
  if not inc      then inc      = 0.1 end

  if type(ord) == "number" then
    ord = { math.floor(ord) }
  else
    table.sort(ord)
    for i=1,#ord do ord[i] = math.floor(ord[i]) end
  end

  local t = M.new_instance()  -- start fresh
  local To = M.To

  for o=1,#ord do
    if ord[o] > M.no then error("Specified ord is greater than no") end
    for m=To.ps[ord[o]],To.pe[ord[o]] do
      t:setCoeff(To[m], startVal)
      startVal = startVal + inc
    end
  end
  return t
end

-- returns a tpsa filled up to its maximum order
function M.full()  -- same as t:pow(no)
  local b, r, tmp, p = M.ord{0,1}, M.new_instance(), M.new_instance(), M.no
  r:setConst(1)

  while p > 0 do
    if p%2==1 then
      r.mul(r, b, tmp)
      r, tmp = tmp, r
      p = p - 1
    end
    b.mul(b, b, tmp)
    b, tmp = tmp, b
    p = p/2
  end
  if M.mod.destroy then
    b:destroy()
    tmp:destroy()
  end
  return r
end


-- read benchmark input parameters: NV, NO, NL
function M.read_params(fct_name, filename)
  if not filename then filename = fct_name .. "-params.txt" end

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
  assert(#NV == #NO and #NV == #NL)
  return NV, NO, NL
end

return M
