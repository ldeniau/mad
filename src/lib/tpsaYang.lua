local tpsa = { name="yang" }
local MT   = { __index=tpsa }

local ffi = require('ffi')
local format, setmetatable = string.format, setmetatable

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
  // nv = number of variables, no = highest order of TPSA
  void ad_init_(const TNVND* nv, const TNVND* no);

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


local uintPtr  = ffi.typeof("unsigned int [?]") -- serves as pointer or array
local sizetPtr = ffi.typeof("size_t [1]")
local dblPtr   = ffi.typeof("double [1]")

-- Create pointers to some useful literals
local zero_i, one_i = uintPtr(1, 0), uintPtr(1, 1)
local zero_d, one_d = dblPtr(0.0),   dblPtr(1.0)

local initialized = false

-- should be called before any other tpsa function
function tpsa.init(nv, no)
  local errStr = "Invalid Yang tpsa initializer. Use tpsa.init(nv, no) or tpsa({var_names}, no)"

  if     type(nv) == "table"  then nv = #nv
  elseif type(nv) ~= "number" then error(errStr) end
  if     type(no) ~= "number" then error(errStr) end

  if initialized then               -- make sure it is terminated
    yangLib.ad_fini_()              -- before init-ing again
  else
    initialized = true
  end

  yangLib.ad_init_(uintPtr(1, nv), uintPtr(1, no))

  -- reserve should be called right after init, so we'll do it here
  local size = 30000                -- to suffice for allocations
  yangLib.ad_reserve_(uintPtr(1, size))
  return tpsa.new(nv, no)
end

function tpsa.new(nv, no)
  local t = { nv=nv, no=no, idx=uintPtr(1) }

  yangLib.ad_alloc_(t.idx)

  return setmetatable(t, MT)
end

function tpsa.same(t)
  return t.new(t.nv, t.mo)
end

function tpsa.setConst(t, value)
  yangLib.ad_const_(t.idx, dblPtr(value))
end

function tpsa.setCoeff(t, mon, coeff)
  -- mon = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}

  local indexes, size = uintPtr(#mon, mon), sizetPtr(#mon)

  yangLib.ad_pok_(t.idx, indexes, size, dblPtr(coeff))
end

function tpsa.getCoeff(t, mon)
  -- mon = see setCoeff
  local indexes, size, coeff = uintPtr(#mon, mon), sizetPtr(#mon), dblPtr(1)

  yangLib.ad_pek_(t.idx, indexes, size, coeff)
  return tonumber(coeff[0])
end

function tpsa.cpy(src, dst)
  if not dst then dst = src:same() end
  yangLib.ad_copy_(src.idx, dst.idx)
  return dst
end

function tpsa.mul(t1, t2, r)
  if r.idx[0] == t1.idx[0] or
     r.idx[0] == t2.idx[0] then
    local rn = r:same()
    yangLib.ad_mult_(t1.idx, t2.idx, rn.idx)

    r.idx, rn.idx = rn.idx, r.idx -- replace r by new r
    rn:destroy()
  else
    yangLib.ad_mult_(t1.idx, t2.idx, r.idx)
  end
end

function tpsa.cct(a, b, c)
  -- a, b, c should be compatible arrays of TPSAs, starting from 1

  local bIdxs, bSize = uintPtr(#b), uintPtr(1, #b)
  for i=1,#b do bIdxs[i-1] = b[i].idx[0] end

  for i=1,#a do
    yangLib.ad_subst_(a[i].idx, bIdxs, bSize, c[i].idx)
  end
end

function tpsa.destroy(t)
  yangLib.ad_free_(t.idx)
end

function tpsa.print(t)
  yangLib.ad_print_(t.idx)
end


return tpsa
