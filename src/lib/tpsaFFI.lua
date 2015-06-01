local ffi = require('ffi')
local tonumber, typeof = tonumber, ffi.typeof
local type = type
-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local clib = ffi.load(PATH .. "/tpsa-ffi/libtpsa-ffi.so")

ffi.cdef[[
  // --- types -----------------------------------------------------------------

  struct _IO_FILE;
  typedef struct _IO_FILE FILE;

  typedef double           num_t;
  typedef unsigned char    ord_t;
  typedef unsigned int     bit_t;
  typedef const char*      str_t;
  typedef struct tpsa      T;
  typedef struct tpsa_desc D;

  struct tpsa { // warning: must be kept identical to C definition
    D      *desc;
    ord_t   lo, hi, mo; // lowest/highest used ord, trunc ord
    bit_t   nz;
    int     tmp;
    num_t   coef[?];
  };

  // --- interface -------------------------------------------------------------

  // --- --- DESC --------------------------------------------------------------

  D*    mad_tpsa_dnew    (int nv, const ord_t var_ords[], const ord_t map_ords_[], str_t var_nam_[]);
  D*    mad_tpsa_dnewk   (int nv, const ord_t var_ords[], const ord_t map_ords_[], str_t var_nam_[],
                          int nk, const ord_t knb_ords[], ord_t dk); // knobs
  void  mad_tpsa_ddel    (D *d);

  // --- --- DESC introspection ------------------------------------------------
  int   mad_tpsa_size    (const D *d, ord_t *t_mo ); // if not 0 < *t_mo <= d_mo then *t_mo = d_mo
  ord_t mad_tpsa_gtrunc  (      D *d, ord_t  g_to_); // if not 0 <= g_to <= d_mo then  g_to = d_mo

  // --- --- TPSA --------------------------------------------------------------
  // --- --- ctors, dtor
  T*    mad_tpsa_new     (D *d, ord_t mo_); // if not 0 < mo <= d_mo then mo = d_mo
  T*    mad_tpsa_same    (const T *t);
  void  mad_tpsa_copy    (const T *t, T *d);
  void  mad_tpsa_clear   (      T *t);
  void  mad_tpsa_del     (      T *t);

  // --- --- indexing / monomials
  const ord_t*
        mad_tpsa_mono    (const T *t, int i, int *n, ord_t *total_ord_);
  int   mad_tpsa_midx    (const T *t, int n, const ord_t m[]);
  int   mad_tpsa_midx_sp (const T *t, int n, const int   m[]); // sparse mono [(i,o)]

  // --- --- accessors
  void  mad_tpsa_set0    (      T *t,        num_t v);
  void  mad_tpsa_seti    (      T *t, int i, num_t v);
  void  mad_tpsa_setm    (      T *t, int n, const ord_t m[], num_t v);
  void  mad_tpsa_setm_sp (      T *t, int n, const int   m[], num_t v);

  num_t mad_tpsa_geti    (const T *t, int i);
  num_t mad_tpsa_getm    (const T *t, int n, const ord_t m[]);
  num_t mad_tpsa_getm_sp (const T *t, int n, const int   m[]);

  // --- --- operations
  num_t mad_tpsa_nrm1    (const T *t, const T *t2_);
  num_t mad_tpsa_nrm2    (const T *t, const T *t2_);
  void  mad_tpsa_der     (const T *a,       T *c, int var);
  void  mad_tpsa_mder    (const T *a,       T *c, int n, const ord_t m[]);
  // void  mad_tpsa_pos     (const T *a,             T *c);

  void  mad_tpsa_scl        (const T *a, num_t ca, T *c);                               // aliasing OK
  void  mad_tpsa_axpb       (num_t a, const T *x, num_t b,                      T *r);  // aliasing OK
  void  mad_tpsa_axpbypc    (num_t a, const T *x, num_t b, const T *y, num_t c, T *r);  // aliasing OK
  void  mad_tpsa_axypb      (num_t a, const T *x,          const T *y, num_t b, T *r);  // (x,y) != r
  void  mad_tpsa_axypbzpc   (num_t a, const T *x,          const T *y, num_t b,
                                                           const T *z, num_t c, T *r);  // (x,y) != r
  void  mad_tpsa_ax2pby2    (num_t a, const T *x, num_t b, const T *y, T *r);           // x != r
  void  mad_tpsa_ax2pby2pcz2(num_t a, const T *x, num_t b, const T *y, num_t c, const T *z, T *r); // x != r



  void  mad_tpsa_inv     (const T *a, T *c);
  void  mad_tpsa_sqrt    (const T *a, T *c);
  void  mad_tpsa_invsqrt (const T *a, T *c);
  void  mad_tpsa_exp     (const T *a, T *c);
  void  mad_tpsa_log     (const T *a, T *c);
  void  mad_tpsa_sin     (const T *a, T *c);
  void  mad_tpsa_cos     (const T *a, T *c);
  void  mad_tpsa_sinh    (const T *a, T *c);
  void  mad_tpsa_cosh    (const T *a, T *c);
  void  mad_tpsa_sincos  (const T *a, T *s, T *c);
  void  mad_tpsa_sincosh (const T *a, T *s, T *c);
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
  void  mad_tpsa_div     (const T *a, const T *b, T *c);
  void  mad_tpsa_divc    (num_t    v, const T *a, T *c);
  void  mad_tpsa_pow     (const T *a,             T *c, int p);
  void  mad_tpsa_poisson (const T *a, const T *b, T *c, int n);

  void  mad_tpsa_axpby   (num_t ca, const T *a, num_t cb, const T *b, T *c);
  void  mad_tpsa_axpb    (num_t ca, const T *a,           const T *b, T *c);
  void  mad_tpsa_scale   (num_t ca, const T *a,                       T *c);

  void  mad_tpsa_compose (int   sa, const T *ma[], int sb,   const T *mb[], int sc, T *mc[]);
  void  mad_tpsa_minv    (int   sa, const T *ma[], int sc,         T *mc[]);
  void  mad_tpsa_pminv   (int   sa, const T *ma[], int sc,         T *mc[], int row_select[]);

  void  mad_tpsa_scan_coef (      T *t, FILE *stream_);
  void  mad_tpsa_print     (const T *t, FILE *stream_);
  void  mad_tpsa_debug     (const T *t);
  D*    mad_tpsa_desc_scan (FILE *stream_);

  // ---------------------------------------------------------------------------
]]

-- define types just once and use their constructor
local tpsa_t   = typeof("T")
local tpsa_arr = typeof("T*         [?]")
local tpsa_carr= typeof("const T*   [?]")
local mono_t   = typeof("const ord_t[?]")
local smono_t  = typeof("const int  [?]")
local ord_ptr  = typeof("      ord_t[1]")
local int_ptr  = typeof("      int  [1]")
local str_arr  = typeof("      str_t[?]")

local M = { name = "tpsa", mono_t = mono_t}
local MT   = { __index = M }

ffi.metatype("struct tpsa", MT)

M.clib_ = clib
M.count = 0

-- CONSTRUCTORS ----------------------------------------------------------------
local tmp_stack

-- {vo={2,2} [, mo={3,3}] [, v={'x', 'px'}] [, ko={1,1,1} ] [, dk=2]}
-- {vo={2,2} [, mo={3,3}] [, v={'x', 'px'}] [, nk=3,ko=1  ] [, dk=2]}
function M.get_desc(args)
  assert(args and args.vo, "not enough args for TPSA descriptor")

  local nv, dk = #args.vo, args.dk or 0
  local cvar_ords  = mono_t(nv, args.vo)
  local cvar_names = args.v  and assert(#args.v  == nv, 'not enough var names')
                             and str_arr(nv, args.v)
  local cmap_ords  = args.mo and assert(#args.mo == nv, 'not enough map ords')
                             and mono_t(nv, args.mo)

  local d
  local nk = args.nk or type(args.ko) == "table" and #args.ko or 0
  if nk ~= 0 then
    local cknb_ords = assert(args.ko, "knob orders not specified") and mono_t(nk, args.ko)
    d = clib.mad_tpsa_dnewk(nv, cvar_ords, cmap_ords, cvar_names,
                            nk, cknb_ords, dk)
  else
    d = clib.mad_tpsa_dnew (nv, cvar_ords, cmap_ords, cvar_names)
  end
  tmp_stack = { top=0 }
  return d
end

function M.gtrunc(desc, o)
  -- use without `o` to get current truncation order
  return clib.mad_tpsa_gtrunc(desc, o)
end

function M.set_tmp(t)
  t.tmp = 1
  return t
end

function M.set_var(t)
  t.tmp = 0
  return t
end

function M.release(t)
  if t.tmp ~= 0 then
    tmp_stack.top = tmp_stack.top + 1
    tmp_stack[tmp_stack.top] = t
  end
end

function M.allocate(desc, mo_)
  mo_      = ord_ptr(mo_ or -1)
  local nc = clib.mad_tpsa_size(desc, mo_)
  local t  = tpsa_t(nc)  -- automatically initialized with 0s
  t.desc   = desc
  t.mo     = mo_[0]
  t.lo     = t.mo
  M.count  = M.count + 1
  return t, nc
end

function M.same(a,b)
  local t
  if tmp_stack.top > 0 then
    t = tmp_stack[tmp_stack.top]
    tmp_stack.top = tmp_stack.top - 1
  else
    t = M.allocate(a.desc)
  end
  return t:set_var()
end

function M.cpy(src, dst)
  if not dst then dst = src:same() end
  clib.mad_tpsa_copy(src, dst)
  return dst
end

-- INDEXING / MONO -------------------------------------------------------------
function M.get_idx(t,m)
  return clib.mad_tpsa_midx(t,#m,mono_t(#m,m))
end

function M.get_idx_sp(t,m)
  return clib.mad_tpsa_midx_sp(t,#m,smono_t(#m,m))
end

function M.get_mono(t,i)
  local nv, ord = int_ptr(), ord_ptr()
  local cmono = clib.mad_tpsa_mono(t,i,nv,ord)
  local m = {}
  for i=1,nv[0] do
    m[i] = cmono[i-1]
  end
  return m, ord[0]
end

-- PEEK & POKE -----------------------------------------------------------------

M.get_at = clib.mad_tpsa_geti

function M.get(t, m)
  return clib.mad_tpsa_getm(t, #m, mono_t(#m,m))
end

function M.get_sp(t,m)
  -- m = {idx1, ord1, idx2, ord2, ... }
  return clib.mad_tpsa_getm_sp(t, #m, smono_t(#m,m))
end

M.set0   = clib.mad_tpsa_set0
M.set_at = clib.mad_tpsa_seti

function M.set(t, m, v)
  clib.mad_tpsa_setm(t, #m, mono_t(#m, m), v)
end

function M.set_sp(t, m, v)
  clib.mad_tpsa_setm_sp(t, #m, smono_t(#m,m), v)
end

-- OPERATIONS ------------------------------------------------------------------
-- --- UNARY -------------------------------------------------------------------
function M.nrm1(t1, t2_)
  return clib.mad_tpsa_nrm1(t1, t2_)
end

function M.nrm2(t1, t2_)
  return clib.mad_tpsa_nrm2(t1, t2_)
end

function M.der(src, var, dst)
  dst = dst or src:same()
  clib.mad_tpsa_der(src, var, dst)
  return dst
end

function M.derm(src, m, dst)
  dst = dst or src:same()
  clib.mad_tpsa_der_m(src,#m,mono_t(#m,m),dst)
  return dst
end

function M.scale(val, src, dst)
  clib.mad_tpsa_scale(val, src, dst)
end

function M.divc(src, val, dst)
  clib.mad_tpsa_divc(val,src,dst)
end

-- --- BINARY ------------------------------------------------------------------
function M.add(a, b, c)
  -- c should be different from a and b
  clib.mad_tpsa_add(a, b, c)
end

function M.sub(a, b, c)
  -- c should be different from a and b
  clib.mad_tpsa_sub(a, b, c)
end

function M.mul(a, b, c)
  -- c should be different from a and b
  clib.mad_tpsa_mul(a,b,c)
end

function M.div(a, b, c)
  clib.mad_tpsa_div(a,b,c)
end

-- unused yet
--function M.pow(a, p)
--  local r = a:same()
--  clib.mad_tpsa_pow(a, r, p)
--  return r
--end

function M.poisson(a, b, c, n)
  c = c or a:same()
  clib.mad_tpsa_poisson(a, b, c, n)
end

function M.axpby(v1, a, v2, b, c)
  clib.mad_tpsa_axpby(v1, a, v2, b, c)
end

function M.axpb(v, a, b, c)
  clib.mad_tpsa_axpb(v, a, b, c)
end

-- --- OVERLOADING -------------------------------------------------------------
function MT.__add(a, b)
  if type(a) == "number" then
    a,b = b,a
  end
  if a.hi == 0 then  -- promote to number
    return a.coef[0] + b
  end
  local c
  if type(b) == "number" then
    c = a:cpy()
    clib.mad_tpsa_seti(c,0,a.coef[0]+b)
    a:release()
  else
    c = a:same(b)
    clib.mad_tpsa_add(a,b,c)
    a:release()
    b:release()
  end
  return c:set_tmp()
end

function MT.__sub(a, b)
  local c
  if type(a) == "number" then
    c = b:same()
    clib.mad_tpsa_scale(-1, b, c)
    clib.mad_tpsa_seti(c,0,c.coef[0]+a)
    b:release()
  elseif type(b) == "number" then
    c = a:cpy()
    clib.mad_tpsa_seti(c,0,c.coef[0]-b)
    a:release()
  else
    c = a:same()
    clib.mad_tpsa_sub(a,b,c)
    a:release()
    b:release()
  end
  return c:set_tmp()
end

function MT.__mul(a,b)
  if type(a) == "number" then
    a,b = b,a
  end

  if a.hi == 0 then  -- promote to number
    return a.coef[0] * b
  end

  local c
  if type(b) == "number" then
    c = a:same()
    clib.mad_tpsa_scale(b,a,c)
    a:release()
  else
    c = a:same()
    clib.mad_tpsa_mul(a,b,c)
    a:release()
    b:release()
  end
  return c:set_tmp()
end

function MT.__div(a,b)
  local c
  if type(a) == "number" then
    c = b:same()
    clib.mad_tpsa_divc(a,b,c)
    b:release()
  elseif type(b) == "number" then
    c = a:same()
    clib.mad_tpsa_scale(1/b,a,c)
    a:release()
  else
    c = a:same()
    clib.mad_tpsa_div(a,b,c)
    a:release()
    b:release()
  end
  return c:set_tmp()
end

function MT.__pow(a,p)
  if type(a) == "number" then error("NYI") end
  if a.hi == 0 then
    return a.coef[0] ^ p
  end
  local c = a:same()
  clib.mad_tpsa_mul(a,a,c)
  if p > 2 then
    local tmp = a:same()
    for i=2,p do
      clib.mad_tpsa_mul(a,c,tmp)
      c, tmp = tmp, c
    end
    tmp:release()
  end
  a:release()
  return c:set_tmp()
end

-- MAPS ------------------------------------------------------------------------

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

-- FUNCTIONS -------------------------------------------------------------------

function M.inv(a)
  local c = a:same()
  clib.mad_tpsa_inv(a,c)
  a:release()
  return c:set_tmp()
end

function M.sqrt(a)
  local c = a:same()
  clib.mad_tpsa_sqrt(a,c)
  a:release()
  return c:set_tmp()
end

function M.invsqsrt(a)
  local c = a:same()
  clib.mad_tpsa_invsqrt(a,c)
  a:release()
  return c:set_tmp()
end

function M.exp(a)
  local c = a:same()
  clib.mad_tpsa_exp(a,c)
  return c
end

function M.log(a)
  local c = a:same()
  clib.mad_tpsa_log(a,c)
  return c
end

function M.sin(a)
  local c = a:same()
  clib.mad_tpsa_sin(a,c)
  return c
end

function M.cos(a)
  local c = a:same()
  clib.mad_tpsa_cos(a,c)
  return c
end

function M.sinh(a)
  local c = a:same()
  clib.mad_tpsa_sinh(a,c)
  return c
end

function M.cosh(a)
  local c = a:same()
  clib.mad_tpsa_cosh(a,c)
  return c
end

function M.sincos(a, s, c)
  clib.mad_tpsa_sincos(a,s,c)
end

function M.sincosh(a, s, c)
  clib.mad_tpsa_sincosh(a,s,c)
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

-- I/O -------------------------------------------------------------------------
function M.print(a, file)
  clib.mad_tpsa_print(a,file)
end

function M.read(file)
  local d = clib.mad_tpsa_desc_scan(file)
  local t = M.allocate(d)
  clib.mad_tpsa_scan_coef(t,file)
  return t
end

function M.read_into(t, file)
  -- header is ignored, so make sure input is compatible with t (same nv,nk)
  clib.mad_tpsa_desc_scan(file)
  clib.mad_tpsa_scan_coef(t,file)
end



-- debugging -------------------------------------------------------------------

M.debug = clib.mad_tpsa_debug

-- interface for benchmarking --------------------------------------------------

function M.getm(t, m, l, res)
  -- m should be a t.mono_t of length l
  res = clib.mad_tpsa_getm(t, l, m)
  return res
end

function M.der_raw(t_in, v, t_out)
  clib.mad_tpsa_der(t_in, v, t_out)
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
