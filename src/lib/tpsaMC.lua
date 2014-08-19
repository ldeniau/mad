local tpsa = {} -- the module's name
tpsa.name = "mapClass"


ffi = require('ffi')
-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local mapLib = ffi.load(PATH .. '/tpsa-mc/TPSALib-MC.so')

ffi.cdef[[
typedef struct tpsa_t tpsa_t;

  tpsa_t* tpsa_create(int nv, int mo);
  void tpsa_destroy(tpsa_t*);
  void tpsa_copy(tpsa_t* src, tpsa_t* dest);

  void tpsa_setConst(tpsa_t*, double val);
  void tpsa_setCoeff(tpsa_t*, const unsigned char* mon,
                     const int monLen, const double val);
  double tpsa_getCoeff(const tpsa_t*, const unsigned char* mon,
                       const int monLen);

  void tpsa_add(tpsa_t* op1, tpsa_t* op2, tpsa_t* res);
  void tpsa_mul(tpsa_t* op1, tpsa_t* op2, tpsa_t* res);
  void tpsa_concat(tpsa_t* ma, int aLen, tpsa_t* mb, int bLen,
                   tpsa_t* mc, int cLen);

  void tpsa_print(tpsa_t*);
]]

-- pointer type to array of chars, used for monomials
local uchrPtr = ffi.typeof("unsigned char[?]")

-- should be called before any other tpsa function
function tpsa.init(nv, mo)
  -- nothing to do
end


function tpsa.new(nv, mo)
  -- allocates just one TPSA and returns it
  return mapLib.tpsa_create(nv, mo)
end


function tpsa.setConst(t, value)
  mapLib.tpsa_setConst(t, value)
end


function tpsa.setCoeff(t, monomial, coeff)
  -- monomial = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}

  local exps = uchrPtr(#monomial, monomial)    -- build the mon
  mapLib.tpsa_setCoeff(t, exps, #monomial, coeff)
end


function tpsa.getCoeff(t, monomial)
  -- monomial = see setCoeff
  return mapLib.tpsa_getCoeff(t, uchrPtr(#monomial, monomial), #monomial)
end


function tpsa.copy(source, dest)
  mapLib.tpsa_copy(source, dest)
end


function tpsa.mul(t1, t2, res)
  mapLib.tpsa_mul(t1, t2, res)
end


function tpsa.concat(a, b, c)
  -- not really implemented in the library
end


function tpsa.destroy(t)
  mapLib.tpsa_destroy(t)
end


function tpsa.print(t)
  mapLib.tpsa_print(t)
end


return tpsa

