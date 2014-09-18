local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.tspa -- Truncated Power Series Algebra

SYNOPSIS

DESCRIPTION

RETURN VALUES

ERRORS

EXAMPLES

SEE ALSO
  None
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local utils  = require"mad.utils"
local ffi    = require"ffi"

-- locals ----------------------------------------------------------------------

local getmetatable, setmetatable = getmetatable, setmetatable
local type, ipairs, concat = type, ipairs, table.concat
local min, max, floor = math.min, math.max, math.floor
local is_list = utils.is_list

-- metatable for the root of all tpsa
local MT = object {}

 -- make the module the root of all tpsa
MT (M)
M.name = 'tpsa'
M.kind = 'tpsa'
M.is_tpsa = true

-- descriptors of all tpsa
M.D = {} -- descriptor
M.T = {} -- descriptor with named vars

-- initialize FFI
local PATH = (...):match("(.+)%.[^%.]+$") or (...) -- current path
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local clib = ffi.load(PATH .. "/../lib/tpsa-ffi/libtpsa-ffi.so")

local static_dcl = [[
typedef unsigned char mono_t;
typedef double        coef_t;
typedef int           idx_t;
typedef struct desc   desc_t;
typedef struct tpsa   tpsa_t;
typedef unsigned int  bit_t;

struct desc {
  int     nc, mo;
  idx_t **l;
  idx_t   psto[?];
  };

struct tpsa { // warning: must be kept identical to LuaJit definition
  desc_t *desc;
  int     mo;
  bit_t   nz;
  coef_t  coef[?];
};

int tpsa_setCoeff(tpsa_t* t, idx_t i, int o, coef_t v);
int tpsa_mul(const tpsa_t* a, const tpsa_t* b, tpsa_t* c);
int tpsa_print(tpsa_t *t);
]]

ffi.cdef(static_dcl)

local desc_t  = ffi.typeof("desc_t    ")
local tpsa_t  = ffi.typeof("tpsa_t    ")
local intArr  = ffi.typeof("int    [?]")
local iptrArr = ffi.typeof("int*   [?]")

-- functions -------------------------------------------------------------------

--------------
-- U utils

local function fun_true() return true end

--------------
-- M monomials

local function mono_val(l, n)
  local a = {}
  for i=1,l do a[i] = n end
  return a
end

local function mono_cpy(a)
  local b = {}
  for i=1,#a do b[i] = a[i] end
  return b
end

local function mono_cat(a)
  local b = {}
  for i=1,#a do
    local ai = a[i]
    for j=1,#ai do b[i] = ai[j] end
  end
  return b
end

local function mono_max(a)
  local m = 0
  for i=1,#a do if a[i]>m then m = a[i] end end
  return m
end

local function mono_sum(a)
  local s = 0
  for i=1,#a do s = s + a[i] end
  return s
end

local function mono_acc(a)
  local s = mono_cpy(a)
  for i=#s-1,1,-1 do s[i] = s[i] + s[i+1] end
  return s
end

local function mono_equ(a,b)
  for i=1,#a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

local function mono_leq(a,b)
  -- partial order relation ({3,0,0} <= {1,1,0})
  for i=#a,1,-1 do
    if     a[i] < b[i] then return true
    elseif a[i] > b[i] then return false
    end
  end
  return true
end

local function melem_leq(a,b)
  for i=1,#a do
    if a[i] > b[i] then return false end
  end
  return true
end

local function mono_add(a,b)
  local c = {}
  for i=1,#a do c[i] = a[i]+b[i] end
  return c
end

local function mono_isvalid(m, a, o, f)
  return mono_sum(m) <= o and melem_leq(m,a) and f(m,a)
end


local function nxt_by_var(a,m,o,f)
  for i=1,#a do
    a[i] = a[i]+1
    if mono_isvalid(a,m,o,f) then
      return true
    end
    a[i] = 0
  end
  return false
end

local function table_by_vars(o,m,f)
  local a = mono_val(#m, 0)
  local v = { o={ [0]=0 }, i={ [0]=0 }, [0]=mono_cpy(a) }
  while nxt_by_var(a,m,o,f) do
    v[#v+1] = mono_cpy(a)
    v.o[#v] = mono_sum(a)
  end
  return v
end

local function table_by_ords(o,a)
  local v = { o={[0]=0}, i={[0]=0}, ps={[0]=0}, pe={[0]=0}, [0]=a[0] }
  for i=1,o do
    v.ps[i]   = #v + 1
    v.pe[i-1] = #v
    for j=1,#a do
      if a.o[j] == i then
        v[#v+1] = a[j]
        v.o[#v] = i
        v.i[#v] = j
        a.i[j]  = #v
      end
    end
  end
  v.ps[o+1] = #v + 1
  v.pe[o]   = #v
  return v
end

------------
-- unit test

local function table_check(D)
  local a, H, Tv, To, index = D.A, D.H, D.Tv, D.To, D.index

  if D.nc~= #Tv                        then return 1e6+0 end
  for i=2,#a do
    if H[i][1] ~= (H[i-1][a[i-1]+1] and H[i-1][a[i-1]+1] or H[i-1][a[i-1]]+1)
                                       then return 1e6+i end
  end
  for i=1,#D.Tv do
    if To.i[Tv.i[i]] ~= i              then return 2e6+i end
    if index(To[i])  ~= i              then return 3e6+i end
    if not mono_equ(To[Tv.i[i]],Tv[i]) then return 4e6+i end
    if not mono_equ(To[Tv.i[i]],Tv[i]) then return 5e6+i end
  end
  return 0
end

local function set_T(D)
  D.Tv = table_by_vars(D.mo, D.A, D.F)
  D.To = table_by_ords(D.mo, D.Tv)
  D.nc = #D.Tv
end

--------------------
-- H indexing matrix

local function index_H(H, a)
  local s, I = 0, 0
  for i=#a,1,-1 do
    I = I + H[i][s + a[i]] - H[i][s]
    s = s + a[i]
  end
  return I
end

local function index_T(D)
  local H, T = D.H, D.Tv.i
  return function (a) return T[ index_H(H,a) ] end
end

local function clear_H(D)
  local a, o, H = D.A, D.mo, D.H
  local sa = mono_acc(a)

  for i=1,#a do -- variables
    for j=min(sa[i],o)+1,#H[i] do
      H[i][j] = nil
    end
  end
end

local function solve_H(D)
  local a, o, Tv, H = D.A, D.mo, D.Tv, D.H
  local sa = mono_acc(a)

  -- solve system of equations
  for i=#a-1,2,-1 do -- variables
    for j=a[i]+2,min(sa[i],o) do -- orders (unknown)
      -- solve the linear (!) equation of one unknown
      local b    = nxt_by_unk(a,i,j)      -- build monomial for last unkown of H
      local idx0 = index_H(H,b)           -- this makes the indexing equation linear
      local idx1 = find_index(Tv,b,idx0)  -- is linear search slow?
      H[i][j] = idx1 - idx0
    end
  end
end

local function build_H(D)
  local a, o, Tv, H = D.A, D.mo, D.Tv, {}

  -- minimal constants for first row
  H[1] = { [0]=0 }
  for j=1,o+1 do -- orders
    H[1][j] = j
  end

  -- remaining rows
  for i=2,#a do -- variables
    H[i] = { [0]=0 }

    -- initial congruence from Tv
    for j=1,#Tv do -- monomials
      if Tv[j][i] ~= Tv[j-1][i] then
        H[i][#H[i]+1] = j
        if Tv[j][i] == 0 then break end
      end
    end

    -- complete row with zeros
    for j=#H[i]+1,o+1 do -- orders
      H[i][j] = 0
    end
  end

  -- close congruence of last var
  H[#a][a[#a]+1] = #Tv+1

  -- update D
  D.H = H
  D.index = index_T(D)
  solve_H(D)
  clear_H(D)
end

local function set_H(D)
  build_H(D)

  -- check consistency (debugging)
  local chk = table_check(D)
  if chk ~= 0 then
    io.write("A= ")   M.print_mono (D.A,'\n')
    io.write("H=")    M.print_table(D.H)
    io.write("Tv= ")  M.print_table(D.Tv);
    io.write("Checking tables consistency... ", chk, '\n')
    error("invalid TPSA descriptor")
  end
end


--------------------
-- L matrix, indexing in polynomials

local function fill_L(oa, ob, D)
  local ps, pe = D.To.ps, D.To.pe
  local rows = pe[oa]-ps[oa]+1
  local cols = pe[ob]-ps[ob]+1
  local size

  if   oa == ob then size = ((rows+1) * cols) / 2
  else               size =   rows    * cols      end

  D.size = D.size + size*4
  return intArr(size, -1)
end

local function hpoly_idx_fun(oa, ob, ps, pe)
  local iao, ibo = ps[oa], ps[ob]  -- offsets
  if oa == ob then
    return function (ia, ib) return ((ia-iao) * (ia-iao+1))/2 + ib-ibo end
  else
    local cols = pe[ob] - ps[ob] + 1
    return function (ia, ib) return (ia-iao)*cols + ib-ibo end
  end
end

local function build_L(oa, ob, D)
  local To, index = D.To, D.index
  local ps, pe = To.ps, To.pe
  local lc = fill_L(oa, ob, D)
  local idx_lc = hpoly_idx_fun(oa, ob, ps, pe)

  for ia=ps[oa],       pe[oa]  do
  for ib=ps[ob],min(ia,pe[ob]) do
    local m = mono_add(To[ia], To[ib])
    if mono_isvalid(m, D.A, D.mo, D.F) then
        lc[ idx_lc(ia,ib) ] = index(m)
    end
  end end

  return lc
end

local function set_L(d)
  local o, ho = d.mo, floor(d.mo * 0.5)
  local L =   iptrArr(o*ho + 1)
  d.size  = d.size + (o*ho + 1)*8 -- pointers
  local ptrs = {}   -- stores lc references so they don't get GC'ed

  for oc=2,o do
    for j=1,oc/2 do -- foreach pair of oa, ob=oc-oa
      local oa, ob = oc-j, j

      local lc = build_L(oa, ob, d)
      L[oa*ho + ob], ptrs[#ptrs+1] = lc, lc
    end
  end
  d.L, d._ptrs = L, ptrs
end

local function new_Ctpsa(t)
  local dp = t.D.cdesc
  local ctpsa = tpsa_t(dp.nc+1)
  ctpsa.desc = dp
  return ctpsa
end

--------------------
-- D tpsa descriptor

 -- get_desc(key, {var_names}, {var_orders}, max_order, predicate)
local function add_desc(s, n, a, o, f)
  if M.trace then
    io.write("creating descriptor for TPSA { ", s, " }\n")
  end
  local ds = concat(a,',')
  local d = M.D[ds]
  if not d then -- build the descriptor
    d = { A=a, mo=o, size=0, F=f or fun_true } -- alphas, order, size and predicate
    set_T(d)
    set_H(d) -- requires Tv
    set_L(d)
    d.cdesc = desc_t(#d.To.ps + 1, {d.nc, d.mo, d.L, d.To.ps});
    d.size = d.size + 4 + 4 + 8 + (#d.To.ps+1) * 4

    -- do not register the descriptor during benchmark
    if not M.benchmark then M.D[ds] = d end
  end
  M.T[s] = { V=n, D=d }
end

 -- get_desc({var_names}, {var_orders}, max_order, predicate)
local function get_desc(n, o, m, f)
  -- build the key (string) from var_names and var_orders
  local s = concat(n,',') .. ':' .. concat(o,',')
  if not M.T[s] then add_desc(s, n, o, m, f) end
  local t = M.T[s]
  -- do not register the descriptor during benchmark
  if M.benchmark then M.T[s] = nil end
  return t
end

-- debugging -------------------------------------------------------------------

local function printf(s, ...)  -- TODO: put this somewhere and import it
  io.write(s:format(...))
end

function M.print_mono(a, term)
  local s = not a[0] and 1 or 0

  io.write(string.format("[ %2d ",a[s]))
  for i=s+1,#a do
    io.write(string.format("%3d ",a[i]))
  end
  io.write(" ]")
  if term then io.write(term) end
end

function M.print_table(t)
  local s = not a[0] and 1 or 0
  for i=s,#a do
    io.write(string.format("%3d: ",i))
    M.print_mono(a[i])
    if a.o then io.write(string.format("%3d ",a.o[i])) end
    if a.i then io.write(string.format("->%3d ",a.i[i])) end
--    if a.index then io.write(string.format(":%3d ",a.index(a[i]))) end
    io.write("\n")
  end
  if a.p then io.write(" Pi: ") M.print_mono(a.p,'\n') end
end

function M.print_vect(t)
  local cf, pe, write, format = t._c.coef, t._T.D.To.pe, io.write, string.format
  write(format("[ nz=%2d mo=%d; ", t._c.nz, t._c.mo))
  for i=0,pe[t._c.mo] do write(format("%.2f ",cf[i])) end
  write(" ]\n")
end

local function print_lc(lc, oa, ob, d)
  local ps, pe = d.To.ps, d.To.pe
  local idx_lc = hpoly_idx_fun(oa, ob, ps, pe)
  for ia=ps[oa],pe[oa] do
    printf("\n  ")
    for ib=ps[ob],min(ia,pe[ob]) do
      printf("%d ", lc[ idx_lc(ia,ib) ])
    end
  end
  printf("\n  ")
end

function M.print_L(t)
  local d = t._T.D
  local l, o, ho = d.L, d.mo, floor(d.mo * 0.5)
  for oc=2,o do
    for j=1,oc/2 do -- foreach pair of oa, ob=oc-oa
      local oa, ob = oc-j, j
      printf("L[%d][%d] = {", oa, ob)
      local lc = l[oa*ho + ob]
      print_lc(lc, oa, ob, d)
    end
  end
end

-- methods ---------------------------------------------------------------------
function M:new()
  return setmetatable({ _T=self._T, _c=new_Ctpsa(self._T), size=self.size },
                        getmetatable(self));
end

local function same(src, dst)
  dst = dst or src:new()
  dst._c.mo, dst._c.nz = src._c.mo, src._c.nz
  return dst
end

function M.cpy(src, dst)
  dst = same(src, dst)

  local pe = src._T.D.To.pe
  local dmo, dcoef, scoef = dst._c.mo, dst._c.coef, src._c.coef
  for i=0,pe[dmo] do dcoef[i] = scoef[i] end
  return dst
end

function M.setCoeff(t, i, v)
  local d = t._T.D
  local o = d.To.o
  if type(i) == "table" then i = d.index(i) end
  if o[i] >= 2 then error("NYI. Poke only order 1 and use mul") end
  clib.tpsa_setCoeff(t._c, i, o[i], v);
end

function M.setConst(t, v)
  clib.tpsa_setCoeff(t._c, 0, 0, v)
end

function M.getCoeff(t, i)
  if type(i) == "table" then i = t._T.D.index(i) end
  return t._c.coef[i]
end

-- interface for benchmarking
function M.init(var_names, mo)
  return M(var_names, mo)
end

function M.mul(a, b, c)
  -- c should be different from a and b
  clib.tpsa_mul(a._c, b._c, c._c)
end

function M.print(t)
  local d, nv, mo = t._T.D, #t._T.V, t._c.mo
  local To, c = d.To, t._c.coef
  local pe, o= To.pe, To.o
  printf("\n%10s, NO =%5d, NV =%5d, INA =%5d\n%s\n",
         "NONAME",d.mo, nv, 0,
         "*********************************************")
  printf("\n    I  COEFFICIENT          ORDER   EXPONENTS\n")
  -- TODO: print "ALL COMPONENTS ZERO" when neccesary
  for i=0,pe[mo] do
    printf("%6d  %21.14E %5d   ", i, c[i], o[i])
    local m = To[i]
    for mi=1,#m do printf("%2d ", m[mi]) end
    printf("\n")
  end
end


-- metamethods -----------------------------------------------------------------

function M.__mul(a, b)
  local r, rcf, scf

  if type(a) == "number" then
    r = same(b)
    local rc = r._c
    rcf, scf = rc.coef, b._c.coef
    for i=0,rc.desc.nc do rcf[i] = a * scf[i] end
  elseif type(b) == "number" then
    r = same(a)
    local rc = r._c
    rcf, scf = rc.coef, a._c.coef
    for i=0,rc.desc.nc do rcf[i] = b * scf[i] end
  elseif a._T == b._T then
    r = b:new()
    clib.tpsa_mul(a._c, b._c, r._c)
  else
    error("invalid or incompatible TPSA")
  end

  return r
end

function M.pow(a, p)
  local b, r = a:cpy(), 1

  while p>0 do
    if p%2==1 then r = r*b end
    b = b*b
    p = floor(p/2)
  end
  return r
end

-- constructors of tpsa:
--   tpsa({var_names}, max_order)
--   tpsa({var_names}, {var_orders})
--   tpsa({var_names}, {var_orders}, max_order)
--   tpsa({var_names}, {var_orders}, {{partial_max_orders}})

function MT:__call(n,o,m,f)
  if type(o) == "number" then                          -- ({var_names}, max_order)
    o, m = mono_val(#n,o), o
  elseif is_list(o) and not m then                     -- ({var_names}, {var_orders})
       m = mono_max(o)
  end

  if type(m) == "number" and is_list(o) then           -- ({var_names}, {var_orders}, max_order)
    self.__index = self  -- inheritance
    local t = get_desc(n,o,m,f)
    local s = 8 + 4 + 4 + (t.D.nc+1)*4
    return setmetatable({_T=t, _c=new_Ctpsa(t), size=s}, self)
  end

  error ("invalid tpsa constructor argument, tpsa({var_names}, {var_orders}, {cpl_orders}) expected")
end

-- end -------------------------------------------------------------------------
return M
