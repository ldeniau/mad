local tpsa = { name="berz", _cnt=0 }
local MT   = { __index=tpsa }

local ffi = require('ffi')
local format, setmetatable = string.format, setmetatable

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

  // sets up the constant value of the TPSA at idx
  void dacon_(int *idx, double *constant);

  // operations between TPSA and constant
  void dacad_(int *t,  int *c, int *r);            // r = t + c
  void dacsu_(int *t,  int *c, int *r);            // r = c - t
  void dasuc_(int *t,  int *c, int *r);            // r = t - c
  void dacmu_(int *t,  int *c, int *r);            // r = t * c
  void dacdi_(int *t,  int *c, int *r);            // r = t / c
  void dadic_(int *t,  int *c, int *r);            // r = c / t
  void dacma_(int *t1, int *t2, int *c, int *r);   // r = t1 + c * t2

  // operations between 2 TPSAs
  void dacop_(int *src, int *dest);
  void daadd_(int *t1, int *t2, int *r);           // r = t1 + t2
  void dasub_(int *t1, int *t2, int *r);           // r = t1 - t2
  void damul_(int *t1, int *t2, int *r);           // r = t1 * t2
  void dadiv_(int *t1, int *t2, int *r);           // r = t1 / t2
  void dasqr_(int *t , int *r);                    // r = t ^ 2

  // mr = m1 o m2  -- m1, m2, mr = compatible arrays of TPSAs
  //               -- s1, s2, s4 = number of vectors in m1, m2, mr
  void dacct_(int *m1, int *s1, int *m2, int *s2, int *mr, int *sr);

  void dainv_(int *m1, int *s1, int *mr, int *sr); // mr = ma ^ -1

  void daabs_(int *t, int *r);                     // r = |t|
  void dapri_(int *idx, int *dest);                // print TPSA at idx on stream dest
]]


-- Fortran only takes pointers, so define their type
-- a pointer to a single value is a length 1 array
local intPtr = ffi.typeof("int    [1]")
local intArr = ffi.typeof("int    [?]")
local dblPtr = ffi.typeof("double [1]")
local name_t = ffi.typeof("char  [11]")

-- Create pointers to some useful literals
local zero_i, one_i, six_i = intPtr(0),   intPtr(1), intPtr(6)
local zero_d, one_d        = dblPtr(0.0), dblPtr(1.0)


local function create(nv, no)
  local r = {}
  r.nv, r.no = nv, no
  r.idx = intPtr()
  local name = name_t(format("Berz%6d", tpsa._cnt))
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
  berzLib.dacma_(t1.idx, t2,idx, intPtr(c), r.idx)
end
-- unary operations -----------------------------------------------------------
function tpsa.inv(ma, mr)
  -- ma, mr = arrays of TPSAs
  local aIdxs, rIdxs = intArr(#ma), intArr(#mr)
  local aSize, rSize = intPtr(#ma), intPtr(#mr)
  for i=1,#ma do aIdxs[i-1] = ma[i].idx[0] end
  for i=1,#mr do rIdxs[i-1] = mr[i].idx[0] end

  berzLib.dainv_(aIdxs, aSize, rIdxs, rSize)
end

function tpsa.abs(t, r)
  berzLib.daabs_(t.idx, r.idx)
end

function tpsa.destroy(t)
  berzLib.dadal_(t.idx, one_i)
end

function tpsa.print(t)
   berzLib.dapri_(t.idx, six_i)     -- prints on stdout, represented by 6 in Fortran
end

return tpsa

