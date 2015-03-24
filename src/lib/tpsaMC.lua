local tpsa = {} -- the module's name
tpsa.name = "mapClass"


local ffi = require('ffi')
-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local mapLib = ffi.load(PATH .. '/tpsa-mc/libtpsa-mc.so')

ffi.cdef[[
  typedef struct tpsa tpsa_t;
  typedef struct map  map_t;

  // -- TPSA -----------------------------------------------------------------
  tpsa_t* tpsa_init    (int nv, int mo);
  tpsa_t* tpsa_copy    (const tpsa_t *src, tpsa_t *dest_);
  tpsa_t* tpsa_same    (const tpsa_t *t);
  void    tpsa_destroy (      tpsa_t *t);

  double  tpsa_get     (const tpsa_t *t, int monLen, const unsigned char *mon);
  void    tpsa_set     (      tpsa_t *t, int monLen, const unsigned char *mon, double val);

  void    tpsa_add     (tpsa_t *a, tpsa_t *b, tpsa_t *c);
  void    tpsa_mul     (tpsa_t *a, tpsa_t *b, tpsa_t *c);
  void    tpsa_div     (tpsa_t *a, tpsa_t *b, tpsa_t *c);

  void    tpsa_print   (tpsa_t *t);

  // -- MAPS -----------------------------------------------------------------
  map_t*  tpsa_map_create (int nv, tpsa_t *ma[]);
  void    tpsa_map_destroy(map_t *m);
  void    tpsa_map_print  (map_t *m);
  void    tpsa_map_compose(map_t *ma, map_t *mb, map_t *mc);
]]

-- pointer type to array of chars, used for monomials
local uchr_ptr = ffi.typeof("unsigned char[?]")
local tpsa_arr = ffi.typeof("tpsa_t*[?]")

local tpsa_MT = {
  __index = tpsa,
  __gc    = mapLib.tpsa_destroy
}

ffi.metatype("tpsa_t", tpsa_MT)

tpsa.init = mapLib.tpsa_init
tpsa.new  = mapLib.tpsa_same
tpsa.same = mapLib.tpsa_same
tpsa.copy = mapLib.tpsa_copy

function tpsa.set(t, monomial, coeff)
  -- monomial = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}

  local exps = uchr_ptr(#monomial, monomial)    -- build the mon
  mapLib.tpsa_set(t, #monomial, exps, coeff)
end

function tpsa.get(t, monomial)
  -- monomial = see set
  return mapLib.tpsa_get(t, #monomial, uchr_ptr(#monomial, monomial))
end

function tpsa.mul(a,b,c)
  mapLib.tpsa_mul(a,b,c)
end

function tpsa.add(a,b,c)
  mapLib.tpsa_add(a,b,c)
end

function tpsa.sub(a,b,c)
  mapLib.tpsa_sub(a,b,c)
end

function tpsa.div(a,b,c)
  mapLib.tpsa_div(a,b,c)
end

tpsa.print = mapLib.tpsa_print

-- MAPS -----------------------------------------------------------------

local map_MT = {
  __gc = mapLib.tpsa_map_destroy,
  __index = { print = mapLib.tpsa_map_print }
}

ffi.metatype("map_t", map_MT)

function tpsa.create_map(tpsa_vars)
  local arr = tpsa_arr(#tpsa_vars, tpsa_vars)
  return mapLib.tpsa_map_create(#tpsa_vars, arr)
end

function tpsa.compose(ma, mb, mc)
  ma = tpsa.create_map(ma)
  mb = tpsa.create_map(mb)
  mc = tpsa.create_map(mc)
  mapLib.tpsa_map_compose(ma,mb,mc)
  return mc
end


return tpsa

