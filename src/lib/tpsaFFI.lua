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

  D*    mad_tpsa_desc_new  (ord_t mo, int nv, const ord_t var_ords[]);
  D*    mad_tpsa_desc_newk (ord_t mo, int nv, const ord_t var_ords[], ord_t mvo, // with knobs
                                      int nk, const ord_t knb_ords[], ord_t mko);
  void  mad_tpsa_desc_del  (      D *d);

  int   mad_tpsa_desc_nc   (const D *d);
  ord_t mad_tpsa_desc_trunc(      D *d, ord_t *to);

  // --- --- TPSA --------------------------------------------------------------

  void  mad_tpsa_copy    (const T *src, T *dst);
  void  mad_tpsa_clean   (      T *t);
  void  mad_tpsa_del     (      T *t);

  void  mad_tpsa_seti    (      T *t, int i, num_t v);
  void  mad_tpsa_setm    (      T *t, int n, const ord_t m[], num_t v);

  num_t mad_tpsa_geti    (const T *t, int i);
  num_t mad_tpsa_getm    (const T *t, int n, const ord_t m[]);

  int   mad_tpsa_idx     (const T *t, int n, const ord_t m[]);

  num_t mad_tpsa_abs     (const T *t);
  num_t mad_tpsa_abs2    (const T *t);
  void  mad_tpsa_rand    (      T *t, num_t low, num_t high, int seed);

  void  mad_tpsa_der     (const T *a, int var,    T *c);
  void  mad_tpsa_pos     (const T *a,             T *c);
  num_t mad_tpsa_comp    (const T *a, const T *b);

  void  mad_tpsa_inv     (const T *a, T *c);
  void  mad_tpsa_sqrt    (const T *a, T *c);
  void  mad_tpsa_isrt    (const T *a, T *c);
  void  mad_tpsa_exp     (const T *a, T *c);
  void  mad_tpsa_log     (const T *a, T *c);
  void  mad_tpsa_sin     (const T *a, T *c);
  void  mad_tpsa_cos     (const T *a, T *c);
  void  mad_tpsa_sincos  (const T *a, T *c);
  void  mad_tpsa_sinh    (const T *a, T *c);
  void  mad_tpsa_cosh    (const T *a, T *c);
  void  mad_tpsa_sirx    (const T *a, T *c);
  void  mad_tpsa_corx    (const T *a, T *c);
  void  mad_tpsa_sidx    (const T *a, T *c);

  void  mad_tpsa_tan     (const T *a, T *c);
  void  mad_tpsa_cot     (const T *a, T *c);
  void  mad_tpsa_asin    (const T *a, T *c);
  void  mad_tpsa_acos    (const T *a, T *c);
  void  mad_tpsa_atan    (const T *a, T *c);
  void  mad_tpsa_acot    (const T *a, T *c);
  void  mad_tpsa_tanh    (const T *a, T *c);
  void  mad_tpsa_coth    (const T *a, T *c);
  void  mad_tpsa_asinh   (const T *a, T *c);
  void  mad_tpsa_acosh   (const T *a, T *c);
  void  mad_tpsa_atanh   (const T *a, T *c);
  void  mad_tpsa_acoth   (const T *a, T *c);

  void  mad_tpsa_erf     (const T *a, T *c);

  void  mad_tpsa_add     (const T *a, const T *b, T *c);
  void  mad_tpsa_sub     (const T *a, const T *b, T *c);
  void  mad_tpsa_mul     (const T *a, const T *b, T *c);
  void  mad_tpsa_pow     (const T *a,             T *c, int p);

  void  mad_tpsa_scale   (num_t ca, const T *a,                       T *c);
  void  mad_tpsa_axpb    (num_t ca, const T *a,           const T *b, T *c);
  void  mad_tpsa_axpby   (num_t ca, const T *a, num_t cb, const T *b, T *c);

  void  mad_tpsa_compose (int   sa, const T* ma[], int sb, const T* mb[], int sc, T* mc[]);
  void  mad_tpsa_minv    (int   sa, const T *ma[],                        int sc, T *mc[]);
  void  mad_tpsa_pminv   (int   sa, const T *ma[], int sc,       T *mc[], int row_select[]);

  void  mad_tpsa_print   (const T *t);

  // ---------------------------------------------------------------------------
]]

-- define types just once as use their constructor
local mono_t   = typeof("ord_t[?]")
local desc_t   = typeof("D       ")
local tpsa_t   = typeof("T       ")
local tpsa_carr = typeof("const T*   [?]")
local tpsa_arr = typeof("T*   [?]")

local M = { name = "tpsa", mono_t = mono_t}
local MT   = { __index = M }

-- helpers ---------------------------------------------------------------------
local function arr_max(a)
  local m = a[1]
  for i=2,#a do
    if a[i] > m then m = a[i] end
  end
  return m
end

-- functions -------------------------------------------------------------------

-- constructors of tpsa:
--   tpsa({var_orders}, max_order)
--   tpsa({var_orders}, max_order,
--        {knb_orders}, max_var_order, max_knb_order)
function M.init(var_ords, mo, knb_ords, mvo, mko)
  local err, knobs = false, false
  if not is_list(var_ords) or type(mo) ~= 'number' then err = 1
  elseif knb_ords and not is_list(knb_ords)        then err = 2
  else  -- no problem, continue building
    -- get a descriptor
    local d
    local nv, vo = #var_ords, mono_t(#var_ords, var_ords)
    if knb_ords then
      local nk, ko = #knb_ords, mono_t(#knb_ords, knb_ords)
      mvo = mvo or arr_max(var_ords)
      mko = mko or arr_max(knb_ords)
      d = clib.mad_tpsa_desc_newk(mo, nv, vo, mvo, nk, ko, mko)
    else
      d = clib.mad_tpsa_desc_new(mo, nv, vo)
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

  error ("Error " .. tostring(err) .. ": invalid tpsa constructor argument. Use:\n"..
         "\ttpsa({var_orders}, max_order) OR\n"..
         "\ttpsa({var_orders}, max_order, {knb_orders}, max_var_order, max_knb_order)\n")
end

function M:new()
  local nc = clib.mad_tpsa_desc_nc(self.desc)
  local t  = tpsa_t(nc)  -- automatically initialized with 0s
  t.desc   = self.desc
  return t
end

M.same = M.new

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

function M.truncate(t, o)
  -- use without `o` to get current truncation order
  o = o and ffi.new("ord_t [1]", o)
  return clib.mad_tpsa_desc_trunc(t.desc, o)
end

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

function M.compose(ma, mb, mc)
  -- ma, mb, mc -- compatible lua arrays of TPSAs
  local cma, cmb, cmc = tpsa_carr(#ma, ma), tpsa_carr(#mb, mb), tpsa_arr(#mc, mc)
  clib.mad_tpsa_compose(#ma, cma, #mb, cmb, #mc, cmc)
end

function M.minv(ma, mc)
  -- ma, mb, mc -- compatible lua arrays of TPSAs
  local cma, cmc = tpsa_carr(#ma, ma), tpsa_arr(#mc, mc)
  clib.mad_tpsa_minv(#ma, cma, #mc, cmc)
end

function M.pminv(ma, mc, rows)
  -- ma, mb, mc -- compatible lua arrays of TPSAs
  local cma, cmc = tpsa_carr(#ma, ma), tpsa_arr(#mc, mc)
  local sel = ffi.new("int[?]", #rows, rows)
  clib.mad_tpsa_pminv(#ma, cma, #mc, cmc, sel)
end

function M.pow(a, p)
  local r = a:new()
  clib.mad_tpsa_pow(a, r, p)
  return r
end

function M.abs(a)
  return clib.mad_tpsa_abs(a)
end

function M.abs2(a)
  return clib.mad_tpsa_abs2(a)
end

function M.rand(a, low, high, seed)
  clib.mad_tpsa_rand(a, low, high, seed)
end

function M.der(src, var, dst)
  clib.mad_tpsa_der(src, var, dst)
end

function M.pos(src, dst)
  clib.mad_tpsa_pos(src, dst)
end

function M.comp(a, b)
  return clib.mad_tpsa_comp(a, b)
end

function M.cma(v, a, b, c)
  clib.mad_tpsa_cma(v, a, b, c)
end

-- FUNCTIONS -------------------------------------------------------------------

function M.inv(a, c)
  clib.mad_tpsa_inv(a, c)
end

function M.sqrt(a, c)
  clib.mad_tpsa_sqrt(a,c)
end

function M.isrt(a, c)
  clib.mad_tpsa_isrt(a,c)
end

function M.exp(a, c)
  clib.mad_tpsa_exp(a,c)
end

function M.log(a, c)
  clib.mad_tpsa_log(a,c)
end

function M.sin(a, c)
  clib.mad_tpsa_sin(a,c)
end

function M.cos(a, c)
  clib.mad_tpsa_cos(a,c)
end

function M.sinh(a, c)
  clib.mad_tpsa_sinh(a,c)
end

function M.cosh(a, c)
  clib.mad_tpsa_cosh(a,c)
end

function M.sincos(a, c)
  clib.mad_tpsa_sincos(a,c)
end

function M.sirx(a, c)
  clib.mad_tpsa_sirx(a,c)
end

function M.corx(a, c)
  clib.mad_tpsa_corx(a,c)
end

function M.sidx(a, c)
  clib.mad_tpsa_sidx(a,c)
end

function M.tan(a, c)
  clib.mad_tpsa_tan(a,c)
end

function M.cot(a, c)
  clib.mad_tpsa_cot(a,c)
end

function M.asin(a, c)
  clib.mad_tpsa_asin(a,c)
end

function M.acos(a, c)
  clib.mad_tpsa_acos(a,c)
end

function M.atan(a, c)
  clib.mad_tpsa_atan(a,c)
end

function M.acot(a, c)
  clib.mad_tpsa_acot(a,c)
end

function M.tanh(a, c)
  clib.mad_tpsa_tanh(a,c)
end

function M.coth(a, c)
  clib.mad_tpsa_coth(a,c)
end

function M.asinh(a, c)
  clib.mad_tpsa_asinh(a,c)
end

function M.acosh(a, c)
  clib.mad_tpsa_acosh(a,c)
end

function M.atanh(a, c)
  clib.mad_tpsa_atanh(a,c)
end

function M.acoth(a, c)
  clib.mad_tpsa_acoth(a,c)
end

function M.erf(a, c)
  clib.mad_tpsa_erf(a,c)
end

-- debugging -------------------------------------------------------------------

M.print = clib.mad_tpsa_print

-- interface for benchmarking --------------------------------------------------

function M.setm(t, m, v, l)
  -- m should be a t.mono_t of length l
  clib.mad_tpsa_setm(t, l, m, v)
end

function M.getm(t, m, l)
  -- m should be a t.mono_t of length l
  return tonumber(clib.mad_tpsa_getm(t, l, m))
end

function M.subst(ma, mb, lb, mc)
    clib.mad_tpsa_compose(1, ma, lb, mb, 1, mc)
end

function M.compose_raw(sa, ma, sb, mb, sc, mc)
  clib.mad_tpsa_compose(sa, ma, sb, mb, sc, mc)
end

function M.minv_raw(sa, ma, sc, mc)
  clib.mad_tpsa_minv(sa, ma, sc, mc)
end

function M.pminv_raw(sa, ma, sc, mc, sel)
  clib.mad_tpsa_pminv(sa, ma, sc, mc, sel)
end

-- end -------------------------------------------------------------------------
return M
