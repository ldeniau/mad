local tpsa = {} -- the module's name
tpsa.name = "yang"

ffi = require('ffi')

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local yangLib = ffi.load(PATH .. '/tpsa-yang/TPSALib-Yang.so')

ffi.cdef[[
  typedef unsigned int TNVND;
  typedef unsigned int TVEC;

  // this should be called before any other ad_* function and
  // followed by call to ad_reserve
  // nv = number of variables, mo = highest order of TPSA
  void ad_init_(const TNVND* nv, const TNVND* mo);

  void ad_reserve_(const TVEC* n);    // reserve space for n TPSA vectors
  void ad_fini_();                    // free resources

  // allocate / free space for 1 TPSA vector
  void ad_alloc_(TVEC* idx);          // idx returns index of new TPSA
  void ad_free_(const TVEC* idx);     // idx specifies which TPSA to free

  // copies from TPSA at isrc to the TPSA at idst
  void ad_copy_(const TVEC* isrc, const TVEC* idst);

  // set / retrieve coefficient value x of monomial c (size n) from TPSA idx
  // c = {1, 0, 2} -> x * z ^ 2
  void ad_pek_(const TVEC* idx, int* c, size_t* n, double* x);
  void ad_pok_(const TVEC* idx, int* c, size_t* n, double* x);
  void ad_const_(const TVEC* idx, const double* r);  // sets the constant
  void ad_reset(const TVEC* idx);      // resets TPSA at idx to constant 0


  void ad_add_(const TVEC* i, const TVEC* j);
  void ad_mult_(const TVEC* ivlhs, const TVEC* ivrhs, TVEC* ivdst);
  void ad_subst_(const TVEC* iv, const TVEC* ibv, const TNVND* nbv,
                 const TVEC* iret);

  // Reset the base vectors call this before a new ad_init() 
  // with nv from ad_nvar(nv)
  void ad_resetvars_(const TNVND* nvar);

  void ad_print_(const TVEC* iv);
]]


-- All methods take pointers as params and return types so create their type
-- only once and use that constructor

-- int* is used both as single integer and as array start, so need '?' decl
local uintPtr = ffi.typeof("unsigned int [?]")
-- double is always used as single value, so no need of '?' declaration
local dblPtr  = ffi.typeof("double [1]")

-- Create pointers to some useful literals
local zero_i, one_i = uintPtr(1, 0), uintPtr(1, 1)
local zero_d, one_d = dblPtr(0.0),   dblPtr(1.0)

local initialized = false

-- should be called before any other tpsa function
function tpsa.init(nv, mo)
  if initialized then               -- make sure it is terminated
    yangLib.ad_fini_()              -- before init-ing again
  else
    initialized = true
  end

  yangLib.ad_init_(uintPtr(1, nv), uintPtr(1, mo))

  -- reserve should be called right after init, so we'll do it here
  local size = 30000                -- to suffice for allocations

  yangLib.ad_reserve_(uintPtr(1, size))
end


function tpsa.new(nv, mo)
  -- allocates just one TPSA and returns it
  local t = {}                      -- the tpsa object
  t.nv    = nv
  t.mo    = mo

  -- allocate memory and save the index in t.idx, which is pointer
  t.idx  = uintPtr(1)               -- size 1 array; don't care of value
  yangLib.ad_alloc_(t.idx)          -- because it is filled here

  return t
end


function tpsa.setConst(t, value)
  yangLib.ad_const_(t.idx, dblPtr(value))
end


function tpsa.setCoeff(t, monomial, coeff)
  -- monomial = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}
  -- if monomial is {0, 0, ... 0} or {} then it is equivalent to setConst

  -- indexes describes which monomial's coefficients are being set by pok
  local indexes = uintPtr(#monomial, monomial)

  -- size_t not compatible with uint, so can't use uintPtr for size
  local size = ffi.new("size_t[1]", #monomial)

  yangLib.ad_pok_(t.idx, indexes, size, dblPtr(coeff))
end


function tpsa.getCoeff(t, monomial)
  -- monomial = see setCoeff
  local indexes = uintPtr(#monomial, monomial)
  local coeff = dblPtr(1)           -- don't care about value, will be filled

  local size = ffi.new("size_t[1]", #monomial)  -- same as in setCoeff
  yangLib.ad_pek_(t.idx, indexes, size, coeff)
  return tonumber(coeff[0])
end


function tpsa.copy(source, dest)
  yangLib.ad_copy_(source.idx, dest.idx)
end


function tpsa.mul(t1, t2, res)
  local i1 = tpsa.new(t1.nv, t1.mo)
  local i2 = tpsa.new(t2.nv, t2.mo)
  tpsa.copy(t1, i1)
  tpsa.copy(t2, i2)

  yangLib.ad_mult_(i1.idx, i2.idx, res.idx)

  tpsa.destroy(i1)
  tpsa.destroy(i2)
end


function tpsa.concat(ma, mb, mc)
  -- ma, mb, mc should be compatible arrays of TPSAs, starting from 1

  local bIdxs, bSize = uintPtr(#mb), uintPtr(1, #mb)
  for i = 1, #mb do bIdxs[i - 1] = mb[i].idx[0] end

  for i = 1, #ma do
    yangLib.ad_subst_(ma[i].idx, bIdxs, bSize, mc[i].idx)
  end
end


function tpsa.destroy(t)
  yangLib.ad_free_(t.idx)
end


function tpsa.print(t)
  yangLib.ad_print_(t.idx)
end


return tpsa

