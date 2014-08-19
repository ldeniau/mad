local tpsa = {} -- the module's name
tpsa.name = "berz"

local ffi, format = require('ffi'), string.format

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local berzLib = ffi.load(PATH .. '/tpsa-berz/TPSALib-Berz.so')

ffi.cdef[[
  // set up the tpsa with maximum order mo, nv vars, printing it on iunit
  void daini_(int *mo, int *nv, int *iunit);

  // allocates n TPSAs, returning their indexes in idxs
  void daall_(int *idxs, int *n, char *charName, int *mo, int *nv);
  
  // deallocates n TPSAs, with indexes idxs
  void dadal_(int *idxs, int *n);

  // seting or getting the coefficient for the monomial with the given exponent in the TPSA at idx
  void dapok_(int *idx, int *exp, double *coeff);
  void dapek_(int *idx, int *exp, double *coeff);

  // sets up the constant value of the TPSA at idx
  void dacon_(int *idx, double *constant);

  // operations between TPSA and constant
  void dacad(int *t, int *c, int *r);           // r = t + c
  void dacsu(int *t, int *c, int *r);           // r = c - t
  void dasuc(int *t, int *c, int *r);           // r = t - c
  void dacmu(int *t, int *c, int *r);           // r = t * c
  void dacdi(int *t, int *c, int *r);           // r = t / c
  void dadic(int *t, int *c, int *r);           // r = c / t
  void dacma(int *t1, int *t2, int *c, int *r); // r = t1 + c * t2

  // operations between 2 TPSAs
  void dacop_(int *source, int *dest);          // copy
  void daadd_(int *op1, int *op2, int *res);    // add
  void dasub_(int *op1, int *op2, int *res);    // substract
  void damul_(int *op1, int *op2, int *res);    // multiply
  void dadiv_(int *op1, int *op2, int *res);    // divide
  void dasqr_(int *op , int *res);              // square (^2)
 
  // mc = ma o mb  -- ma, mb, mc = compatible arrays of TPSAs
  //               -- sa, sb, sc = number of vectors in ma, mb, mc
  void dacct_(int *ma, int *sa, int *mb, int *sb, int *mc, int *sc);
  void dainv_(int *ma, int *sa, int *mr, int *sr);

  void daabs_(int *t, int *r);                   // r = |t|
  void dapri_(int *idx, int *dest);             // print TPSA at idx on stream dest
]]


-- Fortran only takes pointers, so define their type
-- a pointer to a single value is a length 1 array
local intPtr = ffi.typeof("int [?]")
local dblPtr = ffi.typeof("double [?]")
local chrPtr = ffi.typeof("char [?]")

-- Create pointers to some useful literals
local zero_i, one_i, six_i = intPtr(1,0), intPtr(1,1), intPtr(1,6)
local zero_d, one_d        = dblPtr(1,0.0), dblPtr(1,1.0)

-- should be called before any other tpsa function
function tpsa.init(nv, mo)
  berzLib.daini_(intPtr(1,mo), intPtr(1,nv), zero_i)  
end

function tpsa.new(nv, mo)
  -- allocates just one TPSA and returns it
  local t = {}                     -- the tpsa object
  t.nv, t.mo = nv, mo
  local name = format("T%6d", math.random(999999))

  t.idx = intPtr(1)
  berzLib.daall_(t.idx, one_i, chrPtr(#name+1, name), 
                 intPtr(1,t.mo), intPtr(1,t.nv))
  return t
end

function tpsa.setConst(t, value)
  berzLib.dacon_(t.idx, dblPtr(1,value))
end

function tpsa.setCoeff(t, mon, coeff)
  -- mon = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}

  local cmon = intPtr(#mon, mon)
  berzLib.dapok_(t.idx, cmon, dblPtr(1,coeff))
end

function tpsa.getCoeff(t, mon)
  -- monomial = see setCoeff
  local cmon, coeff = intPtr(#mon, mon), dblPtr(1)
  berzLib.dapek_(t.idx, cmon, coeff)
  return tonumber(coeff[0])
end

function tpsa.cpy(source, dest)
  berzLib.dacop_(source.idx, dest.idx)
end

function tpsa.add(t1, t2, res)
  berzlib.add_(t1.idx, t2.idx, res.idx)
end

function tpsa.sub(t1, t2, res)
  berzlib.sub_(t1.idx, t2.idx, res.idx)
end

function tpsa.mul(t1, t2, res)
  berzLib.damul_(t1.idx, t2.idx, res.idx)
end

function tpsa.div(t1, t2, res)
  berzlib.div_(t1.idx, t2.idx, res.idx)
end

function tpsa.sqr(t1, t2, res)
  berzlib.sqr_(t1.idx, t2.idx, res.idx)
end

function tpsa.concat(a, b, c)
  -- a, b, c should be compatible arrays of TPSAs, starting from 1

  local aIdxs, bIdxs, cIdxs = intPtr(#a), intPtr(#b), intPtr(#c)
  local aSize, bSize, cSize = intPtr(1,#a), intPtr(1,#b), intPtr(1,#c)
  for i=1,#a do aIdxs[i-1] = a[i].idx[0] end
  for i=1,#b do bIdxs[i-1] = b[i].idx[0] end
  for i=1,#c do cIdxs[i-1] = c[i].idx[0] end

  berzLib.dacct_(aIdxs, aSize, bIdxs, bSize, cIdxs, cSize)
end

function tpsa.inv(ma, mr)
  -- ma, mr = arrays of TPSAs
  local aIdxs, rIdxs = intPtr(#ma), intPtr(#mr)
  local aSize, rSize = intPtr(1, #ma), intPtr(1, #mr)
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

return tpsa

