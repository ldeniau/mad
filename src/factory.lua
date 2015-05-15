local ffi = require"ffi"

local M = {}  -- this module
M.seed = os.time()
local dbl_ptr  = ffi.typeof("double[1]")
local int_ptr  = ffi.typeof("int   [1]")
local uint_ptr = ffi.typeof("unsigned int [1]")
local size_t_ptr = ffi.typeof("size_t     [1]")

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

local function mono_isvalid(m, a, o, f)
  return mono_sum(m) <= o and melem_leq(m,a) and f(m,a)
end

local function mono_print(m, file)
  file = file or io.output()
  for mi=1,#m do
    fprintf(file, "%d ", m[mi])
  end
end


-- LOCALS ----------------------------------------------------------------------

local function initMons(nv)
  local t = { ps={ [0]=0, [1]=1, [2]=nv+1 }, pe={ [0]=0, [1]=nv } }

  t[0] = mono_val(nv, 0)
  for i=1,nv do
    t[i] = mono_val(nv, 0)
    t[i][i] = 1
  end

  return t
end

function M.make_To(nv, no, ords, f)
  local t = initMons(nv)
  local a = ords or mono_val(nv, no)
        f = f or function() return true end

  local j
  for ord=2,no do
    for i=1,nv do
      j = t.ps[ord-1]

      repeat
        local m = mono_add(t[i], t[j])
        if mono_isvalid(m, a, no, f) then
          t[#t+1] = m
        end
        j = j+1
      until m[i] > a[i] or m[i] >= ord or j > t.pe[ord-1]

    end
    t.pe[ord  ] = #t
    t.ps[ord+1] = #t+1
  end
  return t
end

local function make_To_ffi()
  if M.To_ffi and M.To_ffi.mono_t == M.mod.mono_t
              and M.To_ffi.nv     == M.nv
              and M.To_ffi.no     == M.no
  then return M.To_ffi end

  local To = M.To
  local mono_t = M.mod.mono_t
  if not mono_t then return M.To end

  local To_ffi = { ps=To.ps, pe=To.pe, mono_t=mono_t, nv=M.nv, no=M.no }
  for i=0,#To do To_ffi[i] = mono_t(#To[i], To[i]) end

  M.To_ffi = To_ffi
  return To_ffi
end

function M.make_To_sparse()
  if M.To_sp and M.To_sp.nv == M.nv and M.To_sp.no == M.no then
    return M.To_sp
  end

  local To = M.To
  local To_sp = { ps=To.ps, pe=To.pe, nv=M.nv, no=M.no }
  for m=0,#To do
    local mono_sp = {}
    for v=1,#To[m] do
      if To[m][v] ~= 0 then
        mono_sp[#mono_sp+1] = v
        mono_sp[#mono_sp+1] = To[m][v]
      end
    end
    To_sp[m] = mono_sp
  end

  M.To_sp = To_sp
  return To_sp
end

local function alternate_0s()
  local t = M.new_instance()
  local rand = math.random
  for m=0,#M.To,2 do
    t:set(M.To[m], 1 + m/10)  -- doubles in (0,2) interval
  end
  for m=1,#M.To,2 do
    t:set(M.To[m], 0)
  end
  return t
end


-- ARGUMENTS BUILD -------------------------------------------------------------
-- use functions return to avoid unpack which is not compiled

-- --- PEEK --------------------------------------------------------------------

local function args_getm()
  local args = {             --    raw instance  ,   mono length   , result ptr
    tpsa = function() return M.new_instance()    ,            M.nv             end,
    berz = function() return M.new_instance().idx,            M.nv , dbl_ptr() end,
    yang = function() return M.new_instance().idx, size_t_ptr(M.nv), dbl_ptr() end,
  }
  return make_To_ffi(), args[M.mod.name]()
end

-- --- OPERATIONS --------------------------------------------------------------

local function args_bin_op()
--  return M.full(), M.full(), M.new_instance()
  return alternate_0s(), alternate_0s(), M.new_instance()
end

-- --- SUBST -------------------------------------------------------------------

local function make_cmap(t, refs, cmap)
  for i=1,M.nv do
    refs[i]   = t:cpy()
    cmap[i-1] = type(t) == "table" and refs[i].idx[0] or refs[i]
  end
end

local function args_subst_tpsa(input_template, refs)
  local nv = M.nv
  ffi.cdef("typedef struct tpsa T")
  local tpsa_carr, tpsa_arr  = ffi.typeof("const T* [$]", nv), ffi.typeof("T* [$]", nv)

  local cma, cmb, cmc = tpsa_carr(), tpsa_carr(), tpsa_arr()
  make_cmap(input_template  , refs.ma, cma)
  make_cmap(input_template  , refs.mb, cmb)
  make_cmap(M.new_instance(), refs.mc, cmc)

  return nv, cma, nv, cmb, nv, cmc, refs
end

local function args_subst_berz(input_template, refs)
  local int_arr, nv_ptr = ffi.typeof("int [$]", M.nv), int_ptr(M.nv)

  local cma, cmb, cmc = int_arr(), int_arr(), int_arr()
  make_cmap(input_template  , refs.ma, cma)
  make_cmap(input_template  , refs.mb, cmb)
  make_cmap(M.new_instance(), refs.mc, cmc)

  return nv_ptr, cma, nv_ptr, cmb, nv_ptr, cmc, refs
end

local function args_subst_yang(input_template, refs)
  local uint_arr = ffi.typeof("unsigned int[$]", M.nv)

  local cma, cmb, cmc = uint_arr(), uint_arr(), uint_arr()
  make_cmap(input_template  , refs.ma, cma)
  make_cmap(input_template  , refs.mb, cmb)
  make_cmap(M.new_instance(), refs.mc, cmc)

  return M.nv, cma, uint_ptr(M.nv), cmb, M.nv, cmc, refs
end

local function args_compose()
  local refs = { ma={}, mb={}, mc={} }  -- save some references to avoid GC
  local args = {
    tpsa = args_subst_tpsa,
    berz = args_subst_berz,
    yang = args_subst_yang,
  }
  local templ, rand, val, sgn = M.new_instance(), math.random
  for m=0,#M.To do
    val = rand() + 1                  -- [1, 2)
    sgn = rand() < 0.5 and -1 or 1
    templ:set(M.To[m], sgn * val)              -- (-2,1] U [1, 2)
  end
  return args[M.mod.name](templ, refs)
end

-- --- MINV --------------------------------------------------------------------

local function args_minv_tpsa(refs)
  ffi.cdef("typedef struct tpsa T")
  local cma, cmc = ffi.new("const T* [?]", M.nv), ffi.new("T* [?]", M.nv)

  for i=1,M.nv do
    refs.ma[i], refs.mc[i] = M.rand()  , M:new_instance()
    cma[i-1]  , cmc[i-1]   = refs.ma[i], refs.mc[i]
  end
  return M.nv, cma, M.nv, cmc, refs
end

local function args_minv_berz(refs, t)
  local intArr = ffi.typeof("int [?]")
  local cma, cmc = intArr(M.nv), intArr(M.nv)

  for i=1,M.nv do
    refs.ma[i], refs.mc[i] = M.rand()         , M.new_instance()
    cma[i-1]  , cmc[i-1]   = refs.ma[i].idx[0], refs.mc[i].idx[0]
  end
  return intArr(1,M.nv), cma, intArr(1,M.nv), cmc, refs
end

local function args_minv()
  local refs = { ma={}, mc={} }
  math.randomseed(M.seed)

  if M.mod.name == "berz" then
    return args_minv_berz(refs)
  elseif M.mod.name == "tpsa" then
    return args_minv_tpsa(refs)
  else
    error("Map inversion not implemented")
  end
end

local function args_pminv()
  local sa, ma, sc, mc, refs = args_minv()
  local sel_rows = ffi.new("int[?]", M.nv)
  for i=1,M.nv do sel_rows[i] = i % 2 end
  return sa, ma, sc, mc, sel_rows, refs
end

-- --- FUN ---------------------------------------------------------------------
local function args_fun()
  return M.full(0.9), M.new_instance()
end

--------------------------------------------------------------------------------

-- INTERFACE -------------------------------------------------------------------

function M.new_instance()
  return M.t:same()
end

function M.get_args(fct_name, t)
  local args = {
    get      = function() return M.To end,
    getm     = args_getm,
    get_sp   = function() return M.make_To_sparse() end,

    poisson  = function() return M.rand(M.seed), M.rand(), M.new_instance(), M.nv/2 end,
    mul      = args_bin_op,     -- returns t1, t2, t_out; t1,t2 filled, t_out empty
    div      = args_bin_op,     -- same as ^
    add      = args_bin_op,     -- same as ^
    sub      = args_bin_op,     -- same as ^

    compose_raw = args_compose, -- returns size_a, ma, size_b, mb, size_c, mc, refs
    minv_raw    = args_minv,    -- returns size_a, ma,             size_c, mc, refs
    pminv_raw   = args_pminv,   -- returns size_a, ma,             size_c, mc, selected_rows, refs

    fun      = args_fun,        -- returns t_in, t_out; t_in filled, t_out empty
    inv      = args_fun,
    sqrt     = args_fun,
  }
  return args[fct_name](t)
end

-- M.setup(mod, nv, no)
-- M.setup(mod) when it has been previously used with some (nv, no)
function M.setup(mod, nv, no)
  if not mod or
     not nv and not M.nv or
     not no and not M.no then
    error("Cannot setup factory: not enough args and no previous state")
  end

  if nv and no and (nv ~= M.nv or no ~= M.no) then
    M.nv, M.no, M.To= nv, no, M.make_To(nv, no)
  end
  if mod ~= M.mod then
    M.mod = mod
    math.randomseed(M.seed)
 end
  M.t = M.mod.init(M.nv,M.no)
end

-- EXPORTED UTILS --------------------------------------------------------------
M.mono_val   = mono_val
M.mono_print = mono_print
M.fprintf    = fprintf
M.printf     = function (...) fprintf(io.output(), ...); io:flush() end

function M.print(file, t)
  local To = M.To

  fprintf(file, "\nCOEFFICIENT                \tEXPONENTS\n")

  for m=0,#To do
    local v = t:get(To[m])
    if v ~= 0 then
      fprintf(file, "%20.10E\t", v)
      mono_print(To[m], file)
      fprintf(file, "\n")
    end
  end
end

function M.print_all(file, ts)
  for i=1,#ts do M.print(file, ts[i]) end
end



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
      t:set(To[m], startVal)
      startVal = startVal + inc
    end
  end
  return t
end

function M.full(startVal, inc)
  local ords = {}
  for o=0,M.no do ords[o+1] = o end
  return M.ord(ords, startVal, inc)
end

-- returns a tpsa filled with random numbers
function M.rand(seed_)
  if seed_ then
    math.randomseed(seed_)
  end
  local rand = math.random
  local t = M.new_instance()
  for m=0,#M.To do
    t:set(M.To[m], rand(0,1) + rand())  -- doubles in (0,2) interval
  end
  return t
end

-- returns a tpsa filled up to its maximum order
function M.build_full()  -- same as t:pow(no)
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
function M.read_params(filename)
  filename = filename or "bench-params/one-params.txt"

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
