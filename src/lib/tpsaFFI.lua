local ffi = require('ffi')
local setmetatable, tonumber, typeof = setmetatable, tonumber, ffi.typeof
local is_list = require"mad.utils".is_list

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local clib = ffi.load(PATH .. "/tpsa-ffi/libtpsa-ffi.so")

ffi.cdef[[
  // --- types -----------------------------------------------------------------

  typedef double           num_t;
  typedef unsigned char    ord_t;
  typedef unsigned int     bit_t;
  typedef struct tpsa      T;
  typedef struct tpsa_desc D;

  struct tpsa { // warning: must be kept identical to LuaJit definition
    D      *desc;
    int     mo;
    bit_t   nz;
    num_t   coef[?];
  };

  // --- interface -------------------------------------------------------------

  // --- --- DESC --------------------------------------------------------------

  D*    mad_tpsa_desc_new  (int nv, const ord_t var_ords[], ord_t mo);
  D*    mad_tpsa_desc_newk (int nv, const ord_t var_ords[], ord_t mvo, // with knobs
                            int nk, const ord_t knb_ords[], ord_t mko);
  void  mad_tpsa_desc_del  (struct tpsa_desc *d);

  int   mad_tpsa_desc_nc   (const struct tpsa_desc *d);

  // --- --- TPSA --------------------------------------------------------------

  void  mad_tpsa_copy    (const T *src, T *dst);
  void  mad_tpsa_clean   (      T *t);
  void  mad_tpsa_del     (      T *t);

  void  mad_tpsa_seti    (      T *t, int i, num_t v);
  void  mad_tpsa_setm    (      T *t, int n, const ord_t m[], num_t v);

  num_t mad_tpsa_geti    (const T *t, int i);
  num_t mad_tpsa_getm    (const T *t, int n, const ord_t m[]);

  int   mad_tpsa_idx     (const T *t, int n, const ord_t m[]);

  void  mad_tpsa_add     (const T *a, const T *b, T *c);
  void  mad_tpsa_sub     (const T *a, const T *b, T *c);
  void  mad_tpsa_mul     (const T *a, const T *b, T *c);

  void  mad_tpsa_print   (const T *t);

  // ---------------------------------------------------------------------------
]]

-- define types just once as use their constructor
local mono_t  = typeof("ord_t[?]")
local desc_t  = typeof("D       ")
local tpsa_t  = typeof("T       ")

local M = { name = "tpsa", mono_t = mono_t}
local MT   = { __index = M }

-- functions -------------------------------------------------------------------

-- constructors of tpsa:
--   tpsa({var_orders}, max_var_order)
--   tpsa({var_orders}, max_var_order,
--        {knb_orders}, max_knb_order)
function M.init(var_ords, mvo, knb_ords, mko)
  local err, knobs = false, false
  if not is_list(var_ords) or not mvo                                 then err = true
  elseif knb_ords and (not is_list(knb_ords) or not mko or mvo > mko) then err = true
  else  -- no problem, continue building
    -- get a descriptor
    local d
    local nv, vo = #var_ords, mono_t(#var_ords, var_ords)
    if knb_ords then
      local nk, ko = #knb_ords, mono_t(#knb_ords, knb_ords)
      d = clib.mad_tpsa_desc_newk(nv, vo, mvo, nk, ko, mko)
    else
      d = clib.mad_tpsa_desc_new(nv, vo, mvo)
    end

    -- create & init tpsa
    local nc = clib.mad_tpsa_desc_nc(d)
    local t  = tpsa_t(nc)  -- automatically initialized with 0s
    t.desc   = d

    -- set metatable for type (just once)
    if not M._mt_is_set then
      ffi.metatype("struct tpsa", MT)
      M._mt_is_set = true
    end

    return t
  end

  error ("invalid tpsa constructor argument. Use:\n"..
         "\ttpsa({var_orders}, max_var_order, {knb_orders}, max_knb_order)\n");
end

function M:new()
  local nc = clib.mad_tpsa_desc_nc(self.desc)
  local t  = tpsa_t(nc)  -- automatically initialized with 0s
  t.desc   = self.desc
  return t
end

function M.cpy(src, dst)
  if not dst then dst = src:new() end
  clib.mad_tpsa_copy(src, dst)
  return dst
end

function M.setCoeff(t, m, v)
  clib.mad_tpsa_setm(t, #m, mono_t(#m, m), v)
end

function M.setConst(t, v)
  clib.mad_tpsa_seti(t, 0, v)
end

function M.getCoeff(t, m)
  return tonumber(clib.mad_tpsa_getm(t, #m, mono_t(#m,m)))
end

M.same = M.new

function M.mul(a, b, c)
  -- c should be different from a and b
  clib.mad_tpsa_mul(a,b,c)
end

function M.add(a, b, c)
  -- c should be different from a and b
  clib.mad_tpsa_add(a, b, c)
end

function M.sub(a, b, c)
  -- c should be different from a and b
  clib.mad_tpsa_sub(a, b, c)
end

-- debugging -------------------------------------------------------------------

M.print = clib.mad_tpsa_print

-- interface for benchmarking --------------------------------------------------

function M.setm(t, l, m, v)
  -- m is a t._coef_t (mono_t), l is its length
  clib.mad_tpsa_setm(t, l, m, v)
end

function M.getm(t, l, m)
  -- m is a t._coef_t (mono_t), l is its length
  return tonumber(clib.mad_tpsa_getm(t, l, m))
end

-- end -------------------------------------------------------------------------
return M
