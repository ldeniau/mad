local ffi = require('ffi')
local setmetatable, tonumber, type, typeof = setmetatable, tonumber, type, ffi.typeof

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local _berzLib = ffi.load(PATH .. '/tpsa-ptc/libdabnew.so')

-- make berzLib a proxy in order to automatically prefix function names
local prefix = "__dabnew_MOD_"
local berzLib = setmetatable({}, {
    __index = function(t,k)
        rawset(t,k, _berzLib[prefix..k])  -- cache the value
        return t[k]
    end,
    __newindex = function(t,k,v)
        error("You should not write to the library proxy")
    end
  })

-- read function definitions
local file = assert(io.open(PATH .. "/tpsa-ptc/c_dabnew.h", "r"))
ffi.cdef(file:read("*all"))
file:close()

-- Fortran only takes pointers, so define their type
-- a pointer to a single value is a length 1 array
local intPtr = typeof("int    [1]")
local intArr = typeof("int    [?]")
local dblPtr = typeof("double [1]")
local chrArr = typeof("char   [?]")
local mono_t

-- Create pointers to some useful literals
local zero_i, one_i = intPtr(0),   intPtr(1)
local zero_d, one_d = dblPtr(0.0), dblPtr(1.0)
local in_stream, out_stream = intPtr(5), intPtr(6)  -- stdin = unit 5, stdout = unit 6


local tpsa = { name = "berz", mono_t = intArr, _cnt = 0 }
local MT   = { __index = tpsa }

local function create(nv, no)
  local r = {}
  r.nv, r.no = nv, no
  r.idx = intPtr()
  local name = chrArr(11, string.format("Berz%6d", tpsa._cnt))
  berzLib.daall1(r.idx, name, intPtr(no), intPtr(nv))
  tpsa._cnt = tpsa._cnt + 1
  return setmetatable(r, MT)
end

-- should be called before any other tpsa function
function tpsa.init(nv, no)
  local errStr = "Invalid Berz tpsa initializer. Use tpsa.init(nv, no) or tpsa({var_names}, no)"

  if     type(nv) == "table"  then nv = #nv
  elseif type(nv) ~= "number" then error(errStr) end
  if     type(no) ~= "number" then error(errStr) end

  berzLib.daini(intPtr(no), intPtr(nv), zero_i)
  mono_t = typeof("int[$]", nv)
  return create(nv, no)
end

function tpsa.new(t)
  return create(t.nv, t.no)
end

tpsa.same = tpsa.new

function tpsa.destroy(t)
  berzLib.dadal(t.idx, one_i)
end

function tpsa.setConst(t, val)
  berzLib.dacon(t.idx, dblPtr(val))
end

function tpsa.setCoeff(t, mon, val)
  -- mon = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}

  local cmon = mono_t(mon)
--  for i=#mon,t.nv-1 do cmon[i] = 0 end  -- fill with 0s
  berzLib.dapok(t.idx, cmon, dblPtr(val))
end

function tpsa.getCoeff(t, mon)
  -- monomial = see setCoeff
  local cmon, val = intArr(t.nv, mon), dblPtr()
  for i=#mon,t.nv-1 do cmon[i] = 0 end
  berzLib.dapek(t.idx, cmon, val)
  return tonumber(val[0])
end

function tpsa.cpy(src, dst)
  if not dst then dst = src:new() end
  berzLib.dacop(src.idx, dst.idx)
  return dst
end

-- binary operations between TPSAs --------------------------------------------
function tpsa.add(t1, t2, r)
  berzLib.daadd(t1.idx, t2.idx, r.idx)
end

function tpsa.sub(t1, t2, r)
  berzLib.dasub(t1.idx, t2.idx, r.idx)
end

function tpsa.mul(t1, t2, r)
  -- r should be different from t1 and t2 to avoid an extra alloc
  berzLib.damul(t1.idx, t2.idx, r.idx)
end

function tpsa.div(t1, t2, r)
  berzLib.dadiv(t1.idx, t2.idx, r.idx)
end

function tpsa.sqr(t1, t2, r)
  berzLib.dasqr(t1.idx, t2.idx, r.idx)
end

function tpsa.poisson(a,b,c,n)
  berzLib.dapoi(a.idx, b.idx, c.idx, intPtr(n))
end


-- binary operations between TPSA and scalar ----------------------------------
function tpsa.cadd(t, c, r)
  berzLib.dacad(t.idx, dblPtr(c), r.idx)
end

function tpsa.csub(t, c, r)
  berzLib.dacsu(t.idx, dblPtr(c), r.idx)
end

function tpsa.subc(t, c, r)
  berzLib.dacad(t.idx, dblPtr(c), r.idx)
end

function tpsa.cmul(t, c, r)
  berzLib.dacmu(t.idx, dblPtr(c), r.idx)
end

function tpsa.cdiv(t, c, r)
  berzLib.dacdi(t.idx, dblPtr(c), r.idx)
end

function tpsa.divc(t, c, r)
  berzLib.dadic(t.idx, dblPtr(c), r.idx)
end

function tpsa.cma(t1, t2, c, r)
  berzLib.dacma(t1.idx, t2.idx, dblPtr(c), r.idx)
end

-- unary operations -----------------------------------------------------------

function tpsa.abs(t)
  local norm = dblPtr()
  berzLib.daabs(t.idx, norm)
  return norm[0]
end

function tpsa.abs2(t)
  local norm = dblPtr()
  berzLib.daabs2(t.idx, norm)
  return norm[0]
end

function tpsa.pos(src, dst)
  berzLib.dapos(src.idx, dst.idx)
end

function tpsa.comp(a, b)
  error("Bug in TPSAlib.f")
  local val = dblPtr()
  berzLib.dacom(a.idx, b.idx, val)
  return val[0]
end

function tpsa.inv(a, b)
  berzLib.dafun(chrArr(5, 'inv '), a.idx, b.idx)
end

function tpsa.sqrt(a, b)
  berzLib.dafun(chrArr(5, 'sqrt'), a.idx, b.idx)
end

function tpsa.isrt(a, b)
  berzLib.dafun(chrArr(5, 'isrt'), a.idx, b.idx)
end

function tpsa.exp(a, b)
  berzLib.dafun(chrArr(5, 'exp '), a.idx, b.idx)
end

function tpsa.log(a, b)
  berzLib.dafun(chrArr(5, 'log '), a.idx, b.idx)
end

function tpsa.sin(a, b)
  berzLib.dafun(chrArr(5, 'sin '), a.idx, b.idx)
end

function tpsa.cos(a, b)
  berzLib.dafun(chrArr(5, 'cos '), a.idx, b.idx)
end

function tpsa.sirx(a, b)
  berzLib.dafun(chrArr(5, 'sirx'), a.idx, b.idx)
end

function tpsa.corx(a, b)
  berzLib.dafun(chrArr(5, 'corx'), a.idx, b.idx)
end

function tpsa.sidx(a, b)
  berzLib.dafun(chrArr(5, 'sidx'), a.idx, b.idx)
end

function tpsa.tan(a, b)
  berzLib.dafun(chrArr(5, 'tan '), a.idx, b.idx)
end

function tpsa.cot(a, b)
  berzLib.dafun(chrArr(5, 'cot '), a.idx, b.idx)
end

function tpsa.asin(a, b)
  berzLib.dafun(chrArr(5, 'asin'), a.idx, b.idx)
end

function tpsa.acos(a, b)
  berzLib.dafun(chrArr(5, 'acos'), a.idx, b.idx)
end

function tpsa.sinh(a, b)
  berzLib.dafun(chrArr(5, 'sinh'), a.idx, b.idx)
end

function tpsa.cosh(a, b)
  berzLib.dafun(chrArr(5, 'cosh'), a.idx, b.idx)
end

function tpsa.atan(a, b)
  berzLib.dafun(chrArr(5, 'atan'), a.idx, b.idx)
end

function tpsa.acot(a, b)
  berzLib.dafun(chrArr(5, 'acot'), a.idx, b.idx)
end

function tpsa.tanh(a, b)
  berzLib.dafun(chrArr(5, 'tanh'), a.idx, b.idx)
end

function tpsa.coth(a, b)
  berzLib.dafun(chrArr(5, 'coth'), a.idx, b.idx)
end

function tpsa.asinh(a, b)
  berzLib.dafun(chrArr(5, 'asnh'), a.idx, b.idx)
end

function tpsa.acosh(a, b)
  berzLib.dafun(chrArr(5, 'acsh'), a.idx, b.idx)
end

function tpsa.atanh(a, b)
  berzLib.dafun(chrArr(5, 'atnh'), a.idx, b.idx)
end

function tpsa.acoth(a, b)
  berzLib.dafun(chrArr(5, 'acth'), a.idx, b.idx)
end

function tpsa.erf(a, b)
  berzLib.dafun(chrArr(5, 'erf '), a.idx, b.idx)
end

function tpsa.der(src, var, dst)
  -- derivate `src` with respect to variable `var`, storing the result in `dst`
  if not dst then dst = src:new() end
  berzLib.dader(intPtr(var), src.idx, dst.idx)
  return dst
end


-- MAPS -----------------------------------------------------------------------
function tpsa.minv(ma, mr)
  -- ma, mr = arrays of TPSAs
  local aIdxs, rIdxs = intArr(#ma), intArr(#mr)
  local aSize, rSize = intPtr(#ma), intPtr(#mr)
  for i=1,#ma do aIdxs[i-1] = ma[i].idx[0] end
  for i=1,#mr do rIdxs[i-1] = mr[i].idx[0] end

  berzLib.dainv(aIdxs, aSize, rIdxs, rSize)
end

function tpsa.pminv(ma, mr, rows)
  -- ma, mr = arrays of TPSAs
  local aIdxs, rIdxs = intArr(#ma), intArr(#mr)
  local aSize, rSize = intPtr(#ma), intPtr(#mr)
  for i=1,#ma do aIdxs[i-1] = ma[i].idx[0] end
  for i=1,#mr do rIdxs[i-1] = mr[i].idx[0] end
  local sel = intArr(#rows, rows)

  berzLib.dapin(aIdxs, aSize, rIdxs, rSize, sel)
end

function tpsa.compose(a, b, c)
  -- a, b, c should be compatible arrays of TPSAs, starting from 1

  local aIdxs, bIdxs, cIdxs = intArr(#a), intArr(#b), intArr(#c)
  local aSize, bSize, cSize = intPtr(#a), intPtr(#b), intPtr(#c)
  for i=1,#a do aIdxs[i-1] = a[i].idx[0] end
  for i=1,#b do bIdxs[i-1] = b[i].idx[0] end
  for i=1,#c do cIdxs[i-1] = c[i].idx[0] end

  berzLib.dacct(aIdxs, aSize, bIdxs, bSize, cIdxs, cSize)
end

-- IO --------------------------------------------------------------------------
function tpsa.print(t)
   berzLib.dapri(t.idx, out_stream)  -- prints on stdout
end

function tpsa.read(t)
   berzLib.darea(t.idx, in_stream)   -- reads from stdin
end

-- UTILS -----------------------------------------------------------------------
function tpsa.global_truncation(ord)
  berzLib.danot(intPtr(ord))
end

-- OVERLOADING -----------------------------------------------------------------
function MT.__add(a,b)
  local c
  if type(a) == "number" then
    c = b:cpy()
    berzLib.dacad(b.idx, dblPtr(a), c.idx)
  elseif type(b) == "number" then
    c = a:cpy()
    berzLib.dacad(a.idx, dblPtr(b), c.idx)
  elseif type(a) == type(b) then
    c = a:same()
    berzLib.daadd(a.idx, b.idx, c.idx)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__sub(a,b)
  local c
  if type(a) == "number" then
    c = b:cpy()
    berzLib.dasuc(b.idx, dblPtr(a), c.idx)
  elseif type(b) == "number" then
    c = a:cpy()
    berzLib.dacsu(a.idx, dblPtr(b), c.idx)
  elseif type(a) == type(b) then
    c = a:same()
    berzLib.dasub(a.idx, b.idx, c.idx)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__mul(a,b)
  local c
  if type(a) == "number" then
    c = b:same()
    berzLib.dacmu(b.idx, dblPtr(a), c.idx)
  elseif type(b) == "number" then
    c = a:same()
    berzLib.dacmu(a.idx, dblPtr(b), c.idx)
  elseif type(a) == type(b) then
    c = a:same()
    berzLib.damul(a.idx, b.idx, c.idx)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__div(a,b)
  local c
  if type(a) == "number" then
    c = b:same()
    berzLib.dadic(b.idx, dblPtr(a), c.idx)
  elseif type(b) == "number" then
    c = a:same()
    berzLib.dacdi(a.idx, dblPtr(b), c.idx)
  elseif type(a) == type(b) then
    c = a:same()
    berzLib.dadiv(a.idx, b.idx, c.idx)
  else
    error("Incompatible operands")
  end
  return c
end

-- interface for benchmarking --------------------------------------------------

function tpsa.setm(t, m, v)
  -- m is a t.mono_t (i.e. intArr) of length nv
  berzLib.dapok(t.idx, m, dblPtr(v))
end

function tpsa.getm(t, m)
  -- m is a t.mono_t (i.e. intArr) of length nv
  local v_ptr = dblPtr()
  berzLib.dapek(t.idx, m, v_ptr)
  return tonumber(v_ptr[0])
end

function tpsa.scale(val,src,dst)
  tpsa.cmul(src,val,dst)
end

function tpsa.subst(ma, mb, lb, mc)
  -- ma, mc are arrays of 1 tpsa; mb is array of `lb` TPSAs; lb == ma[i].nv
  berzLib.dacct(ma, one_i, mb, lb, mc, one_i)
end

function tpsa.compose_raw(sa, ma, sb, mb, sc, mc)
  berzLib.dacct(ma, sa, mb, sb, mc, sc)
end

function tpsa.minv_raw(sa, ma, sc, mc)
  berzLib.dainv(ma, sa, mc, sc)
end

function tpsa.pminv_raw(sa, ma, sc, mc, sel)
  berzLib.dapin(ma, sa, mc, sc, sel)
end

return tpsa

