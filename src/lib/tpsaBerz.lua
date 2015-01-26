local ffi = require('ffi')
local setmetatable, tonumber, typeof = setmetatable, tonumber, ffi.typeof

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local berzLib = ffi.load(PATH .. '/tpsa-berz/libtpsa-berz.so')

ffi.cdef[[
  // set up the tpsa with maximum order no, nv vars, printing it on iunit
  void daini_(int *no, int *nv, int *iunit);

  // allocates n TPSAs, returning their indexes in idxs
  void daall_(int *idxs, int *n, char *charName, int *no, int *nv);

  // deallocates n TPSAs, with indexes idxs
  void dadal_(int *idxs, int *n);

  // seting or getting the monomial's coefficient in the TPSA at idx
  void dapok_(int *idx, int *mon, double *val);
  void dapek_(int *idx, int *mon, double *val);

  // sets up the TPSA at idx as a constant value
  void dacon_(int *idx, double *constant);

  // operations between TPSA and constant
  void dacad_(int *t,  int *c, int *r);            // r = t + c
  void dacsu_(int *t,  int *c, int *r);            // r = c - t
  void dasuc_(int *t,  int *c, int *r);            // r = t - c
  void dacmu_(int *t,  int *c, int *r);            // r = t * c
  void dacdi_(int *t,  int *c, int *r);            // r = t / c
  void dadic_(int *t,  int *c, int *r);            // r = c / t
  void dacma_(int *t1, int *t2, int *c, int *r);   // r = t1 + c * t2

  // operations on a TPSA
  void daabs_(int *a, double *norm);
  void daabs2_(int *a, double *norm);
  void dader_(int *var_idx, int *src, int *dest);
  void dacom_(int *a, int *b, double *dnorm);
  void dafun_(char *name, int *a, int *c);

  // operations between 2 TPSAs
  void dacop_(int *src, int *dest);
  void dapos_(int *src, int *dest);
  void daadd_(int *t1, int *t2, int *r);           // r = t1 + t2
  void dasub_(int *t1, int *t2, int *r);           // r = t1 - t2
  void damul_(int *t1, int *t2, int *r);           // r = t1 * t2
  void dadiv_(int *t1, int *t2, int *r);           // r = t1 / t2
  void dasqr_(int *t , int *r);                    // r = t ^ 2

  // mr = m1 o m2  -- m1, m2, mr = compatible arrays of TPSAs
  //               -- s1, s2, s4 = number of vectors in m1, m2, mr
  void dacct_(int *m1, int *s1, int *m2, int *s2, int *mr, int *sr);

  void dainv_(int *m1, int *s1, int *mr, int *sr); // mr = ma ^ -1

  void dapri_(int *idx, int *dest);                // print TPSA at idx on stream dest
]]

-- Fortran only takes pointers, so define their type
-- a pointer to a single value is a length 1 array
local intPtr = typeof("int    [1]")
local intArr = typeof("int    [?]")
local dblPtr = typeof("double [1]")
local chrArr = typeof("char   [?]")

-- Create pointers to some useful literals
local zero_i, one_i, six_i = intPtr(0),   intPtr(1), intPtr(6)
local zero_d, one_d        = dblPtr(0.0), dblPtr(1.0)


local tpsa = { name = "berz", mono_t = intArr, _cnt = 0 }
local MT   = { __index = tpsa }


local function create(nv, no)
  local r = {}
  r.nv, r.no = nv, no
  r.idx = intPtr()
  local name = chrArr(11, string.format("Berz%6d", tpsa._cnt))
  berzLib.daall_(r.idx, one_i, name, intPtr(no), intPtr(nv))
  tpsa._cnt = tpsa._cnt + 1
  return setmetatable(r, MT)
end

-- should be called before any other tpsa function
function tpsa.init(nv, no)
  local errStr = "Invalid Berz tpsa initializer. Use tpsa.init(nv, no) or tpsa({var_names}, no)"

  if     type(nv) == "table"  then nv = #nv
  elseif type(nv) ~= "number" then error(errStr) end
  if     type(no) ~= "number" then error(errStr) end

  berzLib.daini_(intPtr(no), intPtr(nv), zero_i)
  return create(nv, no)
end

function tpsa.new(t)
  return create(t.nv, t.no)
end

function tpsa.setConst(t, val)
  berzLib.dacon_(t.idx, dblPtr(val))
end

function tpsa.setCoeff(t, mon, val)
  -- mon = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}

  local cmon = intArr(#mon, mon)
  berzLib.dapok_(t.idx, cmon, dblPtr(val))
end

function tpsa.getCoeff(t, mon)
  -- monomial = see setCoeff
  local cmon, val = intArr(#mon, mon), dblPtr()
  berzLib.dapek_(t.idx, cmon, val)
  return tonumber(val[0])
end

function tpsa.cpy(src, dst)
  if not dst then dst = src:new() end
  berzLib.dacop_(src.idx, dst.idx)
  return dst
end

-- binary operations between TPSAs --------------------------------------------
function tpsa.add(t1, t2, r)
  berzLib.daadd_(t1.idx, t2.idx, r.idx)
end

function tpsa.sub(t1, t2, r)
  berzLib.dasub_(t1.idx, t2.idx, r.idx)
end

function tpsa.mul(t1, t2, r)
  -- r should be different from t1 and t2 to avoid an extra alloc
  berzLib.damul_(t1.idx, t2.idx, r.idx)
end

function tpsa.div(t1, t2, r)
  berzLib.dadiv_(t1.idx, t2.idx, r.idx)
end

function tpsa.sqr(t1, t2, r)
  berzLib.dasqr_(t1.idx, t2.idx, r.idx)
end

function tpsa.cct(a, b, c)
  -- a, b, c should be compatible arrays of TPSAs, starting from 1

  local aIdxs, bIdxs, cIdxs = intArr(#a), intArr(#b), intArr(#c)
  local aSize, bSize, cSize = intPtr(#a), intPtr(#b), intPtr(#c)
  for i=1,#a do aIdxs[i-1] = a[i].idx[0] end
  for i=1,#b do bIdxs[i-1] = b[i].idx[0] end
  for i=1,#c do cIdxs[i-1] = c[i].idx[0] end

  berzLib.dacct_(aIdxs, aSize, bIdxs, bSize, cIdxs, cSize)
end


-- binary operations between TPSA and scalar ----------------------------------
function tpsa.cadd(t, c, r)
  berzLib.dacad_(t.idx, intPtr(c), r.idx)
end

function tpsa.csub(t, c, r)
  berzLib.dacsu_(t.idx, intPtr(c), r.idx)
end

function tpsa.subc(t, c, r)
  berzLib.dacad_(t.idx, intPtr(c), r.idx)
end

function tpsa.cmul(t, c, r)
  berzLib.dacmu_(t.idx, intPtr(c), r.idx)
end

function tpsa.cdiv(t, c, r)
  berzLib.dacdi_(t.idx, intPtr(c), r.idx)
end

function tpsa.divc(t, c, r)
  berzLib.dacmu_(t.idx, intPtr(c), r.idx)
end

function tpsa.cma(t1, t2, c, r)
  berzLib.dacma_(t1.idx, t2.idx, intPtr(c), r.idx)
end

-- unary operations -----------------------------------------------------------

function tpsa.abs(t)
  local norm = dblPtr()
  berzLib.daabs_(t.idx, norm)
  return norm[0]
end

function tpsa.abs2(t)
  local norm = dblPtr()
  berzLib.daabs2_(t.idx, norm)
  return norm[0]
end

function tpsa.pos(src, dst)
  berzLib.dapos_(src.idx, dst.idx)
end

function tpsa.comp(a, b)
  error("Bug in TPSAlib.f")
  local val = dblPtr()
  berzLib.dacom_(a.idx, b.idx, val)
  return val[0]
end

function tpsa.inv(a, b)
  berzLib.dafun_(chrArr(5, 'inv '), a.idx, b.idx)
end

function tpsa.sqrt(a, b)
  berzLib.dafun_(chrArr(5, 'sqrt'), a.idx, b.idx)
end

function tpsa.isrt(a, b)
  berzLib.dafun_(chrArr(5, 'isrt'), a.idx, b.idx)
end

function tpsa.exp(a, b)
  berzLib.dafun_(chrArr(5, 'exp '), a.idx, b.idx)
end

function tpsa.log(a, b)
  berzLib.dafun_(chrArr(5, 'log '), a.idx, b.idx)
end

function tpsa.sin(a, b)
  berzLib.dafun_(chrArr(5, 'sin '), a.idx, b.idx)
end

function tpsa.cos(a, b)
  berzLib.dafun_(chrArr(5, 'cos '), a.idx, b.idx)
end

function tpsa.sirx(a, b)
  berzLib.dafun_(chrArr(5, 'sirx'), a.idx, b.idx)
end

function tpsa.corx(a, b)
  berzLib.dafun_(chrArr(5, 'corx'), a.idx, b.idx)
end

function tpsa.sidx(a, b)
  berzLib.dafun_(chrArr(5, 'sidx'), a.idx, b.idx)
end

function tpsa.der(src, var, dst)
  -- derivate `src` with respect to variable `var`, storing the result in `dst`
  if not dst then dst = src:new() end
  berzLib.dader_(intPtr(var), src.idx, dst.idx)
  return dst
end

function tpsa.minv(ma, mr)
  -- ma, mr = arrays of TPSAs
  local aIdxs, rIdxs = intArr(#ma), intArr(#mr)
  local aSize, rSize = intPtr(#ma), intPtr(#mr)
  for i=1,#ma do aIdxs[i-1] = ma[i].idx[0] end
  for i=1,#mr do rIdxs[i-1] = mr[i].idx[0] end

  berzLib.dainv_(aIdxs, aSize, rIdxs, rSize)
end

function tpsa.destroy(t)
  berzLib.dadal_(t.idx, one_i)
end

function tpsa.print(t)
   berzLib.dapri_(t.idx, six_i)     -- prints on stdout, represented by 6 in Fortran
end

-- interface for benchmarking --------------------------------------------------

function tpsa.setm(t, m, v)
  -- m is a t.mono_t (i.e. intArr) of length nv
  berzLib.dapok_(t.idx, m, dblPtr(v))
end

function tpsa.getm(t, m)
  -- m is a t.mono_t (i.e. intArr) of length nv
  local v_ptr = dblPtr()
  berzLib.dapek_(t.idx, m, v_ptr)
  return tonumber(v_ptr[0])
end

function tpsa.subst(ma, mb, lb, mc)
  -- ma, mc are arrays of 1 tpsa; mb is array of `lb` TPSAs; lb == ma[i].nv
  berzLib.dacct_(ma, one_i, mb, lb, mc, one_i)
end

function tpsa.compose_raw(sa, ma, sb, mb, sc, mc)
  berzLib.dacct_(ma, sa, mb, sb, mc, sc)
end

function tpsa.minv_raw(sa, ma, sc, mc)
  berzLib.dainv_(ma, sa, mc, sc)
end

return tpsa

