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

  struct _IO_FILE;
  typedef struct _IO_FILE FILE;

  typedef double           num_t;
  typedef unsigned char    ord_t;
  typedef unsigned int     bit_t;
  typedef struct tpsa      T;
  typedef struct tpsa_desc D;

  struct tpsa { // warning: must be kept identical to LuaJit definition
    D      *desc;
    ord_t   mo, to; // max ord, trunc ord
    bit_t   nz;
    num_t   coef[?];
  };

  // --- interface -------------------------------------------------------------

  // --- --- DESC --------------------------------------------------------------

  D*    mad_tpsa_desc_new  (int nv, const ord_t var_ords[], ord_t vo);
  D*    mad_tpsa_desc_newk (int nv, const ord_t var_ords[], ord_t vo, // with knobs
                            int nk, const ord_t knb_ords[], ord_t ko);
  D*    mad_tpsa_desc_scan (FILE *stream_);

  void  mad_tpsa_desc_del  (      D *d);

  int   mad_tpsa_desc_nc   (const D *d, const ord_t *ord_);
  ord_t mad_tpsa_desc_trunc(      D *d, const ord_t *to_ );
  ord_t mad_tpsa_desc_mo   (const D *d);

  // --- --- TPSA --------------------------------------------------------------

  void  mad_tpsa_copy    (const T *src, T *dst);
  void  mad_tpsa_clean   (      T *t);
  void  mad_tpsa_del     (      T *t);

  void  mad_tpsa_setConst(      T *t,        num_t v);
  void  mad_tpsa_seti    (      T *t, int i, num_t v);
  void  mad_tpsa_setm    (      T *t, int n, const ord_t m[], num_t v);

  num_t mad_tpsa_geti    (const T *t, int i);
  num_t mad_tpsa_getm    (const T *t, int n, const ord_t m[]);

  int   mad_tpsa_get_idx (const T *t, int n, const ord_t m[]);

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
  void  mad_tpsa_cdiv    (num_t    v, const T *a, T *c);
  void  mad_tpsa_pow     (const T *a,             T *c, int p);
  void  mad_tpsa_poisson (const T *a, const T *b, T *c, int n);

  void  mad_tpsa_axpby   (num_t ca, const T *a, num_t cb, const T *b, T *c);
  void  mad_tpsa_axpb    (num_t ca, const T *a,           const T *b, T *c);
  void  mad_tpsa_scale   (num_t ca, const T *a,                       T *c);

  void  mad_tpsa_compose (int   sa, const T *ma[], int sb,   const T *mb[], int sc, T *mc[]);
  void  mad_tpsa_minv    (int   sa, const T *ma[], int sc,         T *mc[]);
  void  mad_tpsa_pminv   (int   sa, const T *ma[], int sc,         T *mc[], int row_select[]);

  void  mad_tpsa_scan_coef(      T *t, FILE *stream_);
  void  mad_tpsa_print    (const T *t, FILE *stream_);
  void  mad_tpsa_print_compact   (const T *t);

  // ---------------------------------------------------------------------------
]]

-- define types just once as use their constructor
local desc_t   = typeof("D       ")
local tpsa_t   = typeof("T       ")
local mono_t   = typeof("const ord_t[?]")
local ord_ptr  = typeof("const ord_t[1]")
local tpsa_arr = typeof("T*   [?]")
local tpsa_carr = typeof("const T*   [?]")

local M = { name = "tpsa", mono_t = mono_t}
local MT   = { __index = M }

ffi.metatype("struct tpsa", MT)

-- helpers ---------------------------------------------------------------------
local function arr_val(l,v)
  local t = {}
  for i=1,l do t[i] = v end
  return t
end

local function arr_max(a)
  local m = a[1]
  for i=2,#a do
    if a[i] > m then m = a[i] end
  end
  return m or 0
end

local function arr_sum(a)
  local s = a[1]
  for i=2,#a do
    s = s + a[i]
  end
  return s
end

local function get_bounded(val, array, var_name, array_name)
  local m = arr_max(array)
  if not val then
    return m
  end

  local s = arr_sum(array)
  local warn_str = "Warning: %s. Constructor has been adjusted"
  if val > s then
    local upper_bound_msg = "%s > sum(%s)"
    val = s        -- limit to the maximum available
    io.stderr:write(warn_str:format(upper_bound_msg:format(var_name, array_name)))

  elseif val < m then
    val = m        -- put the least necessary
    local lower_bound_msg = "%s < max(%s)"
    io.stderr:write(warn_str:format(lower_bound_msg:format(var_name, array_name)))
  end
  return val
end

local function allocate(desc, trunc_ord)
  trunc_ord = trunc_ord or clib.mad_tpsa_desc_mo(desc)
  local nc  = clib.mad_tpsa_desc_nc(desc, ord_ptr(trunc_ord))
  local t   = tpsa_t(nc)  -- automatically initialized with 0s
  t.to      = trunc_ord
  t.desc    = desc
  return t
end


-- functions -------------------------------------------------------------------

local constructor_as_string = {
  [0] = [==[
    tpsa.init({vars} [, vo [, {knobs} [, ko]]])
    tpsa.init(nv, no [, nk [,ko]])
  ]==],                                       -- ALWAYS: sum(vars) >= vo >= ko
  [1] = "tpsa.init({vars})",                  -- vo = max(vars)
  [2] = "tpsa.init({vars}, vo)",              -- vo in [max(vars), sum(vars)]
  [3] = "tpsa.init({vars}, {knobs})",         -- vo = max(vars); ko = max(knobs)
  [4] = "tpsa.init({vars}, vo, {knobs})",     -- [2] for vo; ko = max(knobs)
  [5] = "tpsa.init({vars}, vo, {knobs}, ko)", -- [2] for vo; ko in [max(knobs), sum(knobs)]

  [6] = "tpsa.init(nv,no)",                   -- vars = {no,no,..,no}, nv times
  [7] = "tpsa.init(nv,no,nk,ko)"              -- [6] and [1] for vo; same for ko

}

function M.init(...)
  local err_str  = "Invalid constructor. Did you mean: %s ?"
  local type = type
  local vars, knobs, vo, ko

  local arg = {...}
  -- case 1: tpsa.init({vars})
  if #arg == 1 then
    if type(arg[1]) ~= "table" then error(err_str:format(constructor_as_string[1])) end
    vars = arg[1]

  elseif #arg == 2 then
    -- case 6: tpsa.init(nv,no)
    if type(arg[1]) == "number" then
      if type(arg[2]) ~= "number" then error(err_str:format(constructor_as_string[6])) end
      vars = arr_val(arg[1],arg[2])
    elseif type(arg[1]) == "table" then
      vars  = arg[1]

      -- case 2: tpsa.init({vars}, vo)
      if type(arg[2]) == "number" then
        vo = arg[2]

      -- case 3: tpsa.init({vars}, {knobs})
      elseif type(arg[2]) == "table" then
        knobs = arg[2]
      else
        error(err_str:format(constructor_as_string[2] .. " or " .. constructor_as_string[3]))
      end
    end

  elseif #arg == 3 then
    -- case 4: tpsa.init({vars}, vo, {knobs})
    if type(arg[1]) ~= "table" or type(arg[2]) ~= "number" or type(arg[3]) ~= "table" then
        error(err_str:format(constructor_as_string[4]))
    end
    vars, vo, knobs = arg[1], arg[2], arg[3]

  elseif #arg == 4 then
    -- case 5: tpsa.init({vars}, vo, {knobs}, ko)
    if type(arg[1]) == "table" and type(arg[2]) == "number" and
       type(arg[3]) == "table" and type(arg[4]) == "number" then
      vars , vo = arg[1], arg[2]
      knobs, ko = arg[3], arg[4]

    -- case 7: tpsa.init(nv,no,nk,ko)
    elseif type(arg[1]) == "number" and type(arg[2]) == "number" and
           type(arg[3]) == "number" and type(arg[4]) == "number" then
      vars , vo = arr_val(arg[1],arg[2]), arg[2]
      knobs, ko = arr_val(arg[3],arg[4]), arg[4]
    else
      error(err_str:format(constructor_as_string[5] .. " or " .. constructor_as_string[7]))
    end
  else
    error("Too many arguments to TPSA constructor. Usage: " .. constructor_as_string[0])
  end

  knobs = knobs or {}
  vo = get_bounded(vo,vars ,"vo","vars")
  ko = get_bounded(ko,knobs,"ko","knobs")
  if vo < ko then error("vo < ko") end

  local nv, nk = #vars, #knobs
  vars, knobs = mono_t(nv, vars), mono_t(nk, knobs)
  local d = clib.mad_tpsa_desc_newk(nv,vars,vo, nk,knobs,ko)

  return allocate(d,vo)
end

function M:new(trunc_ord)
  if not trunc_ord then error("use t.same() or specify truncation order") end
  return allocate(self.desc, trunc_ord)
end

function M:same()
  return allocate(self.desc,self.to)
end

function M.cpy(src, dst)
  if not dst then dst = src:same() end
  clib.mad_tpsa_copy(src, dst)
  return dst
end

function M.set(t, m, v)
  clib.mad_tpsa_setm(t, #m, mono_t(#m, m), v)
end

function M.setConst(t, v)
  clib.mad_tpsa_setConst(t, v)
end

function M.get_idx(t,m)
  return clib.mad_tpsa_get_idx(t,#m,mono_t(#m,m))
end

function M.get_at(t,i)
  return clib.mad_tpsa_geti(t,i)
end

function M.set_at(t,i,v)
  clib.mad_tpsa_seti(t,i,v)
end

function M.get(t, m)
  return tonumber(clib.mad_tpsa_getm(t, #m, mono_t(#m,m)))
end

function M.global_truncation(t, o)
  -- use without `o` to get current truncation order
  return clib.mad_tpsa_desc_trunc(t.desc, ord_ptr(o))
end

function M.abs(a)
  return clib.mad_tpsa_abs(a)
end

function M.abs2(a)
  return clib.mad_tpsa_abs2(a)
end

function M.comp(a, b)
  return clib.mad_tpsa_comp(a, b)
end

function M.print(a, file)
  clib.mad_tpsa_print(a,file)
end

function M.read(file)
  local d = clib.mad_tpsa_desc_read(file)
  local t = allocate(d)
  clib.mad_tpsa_scan_coef(t,file)
  return t
end

function M.read_into(t, file)
  -- header is ignored, so make sure input is compatible with t (same nv,nk)
  clib.mad_tpsa_desc_scan(file)
  clib.mad_tpsa_scan_coef(t,file)
end

-- OPERATIONS ------------------------------------------------------------------
-- --- UNARY -------------------------------------------------------------------
function M.rand(a, low, high, seed)
  clib.mad_tpsa_rand(a, low, high, seed)
end

function M.der(src, var, dst)
  dst = dst or src:same()
  clib.mad_tpsa_der(src, var, dst)
  return dst
end

function M.scale(val, src, dst)
  clib.mad_tpsa_scale(val, src, dst)
end

function M.cdiv(val, src, dst)
  clib.mad_tpsa_cdiv(val,src,dst)
end

function M.divc(val, src, dst)
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
  clib.mad_tpsa_axpb(v1, a, v2, b, c)
end

function M.axpb(v, a, b, c)
  clib.mad_tpsa_axpb(v, a, b, c)
end

-- --- OVERLOADING -------------------------------------------------------------
function MT.__add(a, b)
  local c
  if type(a) == "number" then
    c = b:cpy()
    clib.mad_tpsa_seti(c,0,c.coef[0]+a)
  elseif type(b) == "number" then
    c = a:cpy()
    clib.mad_tpsa_seti(c,0,c.coef[0]+b)
  elseif ffi.istype(a,b) then
    c = a:same()
    clib.mad_tpsa_add(a,b,c)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__sub(a, b)
  local c
  if type(a) == "number" then
    c = b:same()
    clib.mad_tpsa_scale(-1, b, c)
    clib.mad_tpsa_seti(c,0,c.coef[0]+a)
  elseif type(b) == "number" then
    c = a:cpy()
    clib.mad_tpsa_seti(c,0,c.coef[0]-b)
  elseif ffi.istype(a,b) then
    c = a:same()
    clib.mad_tpsa_sub(a,b,c)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__mul(a,b)
  local c
  if type(a) == "number" then
    c = b:same()
    clib.mad_tpsa_scale(a,b,c)
  elseif type(b) == "number" then
    c = a:same()
    clib.mad_tpsa_scale(b,a,c)
  elseif ffi.istype(a,b) then
    c = a:same()
    clib.mad_tpsa_mul(a,b,c)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__div(a,b)
  local c
  if type(a) == "number" then
    c = b:same()
    clib.mad_tpsa_divc(a,b,c)
  elseif type(b) == "number" then
    c = a:same()
    clib.mad_tpsa_cdiv(b,a,c)
  elseif ffi.istype(a,b) then
    c = a:same()
    clib.mad_tpsa_div(a,b,c)
  else
    error("Incompatible operands")
  end
  return c
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

-- debugging -------------------------------------------------------------------

M.debug = clib.mad_tpsa_print_compact

-- interface for benchmarking --------------------------------------------------

function M.setm(t, m, l, v)
  -- m should be a t.mono_t of length l
  clib.mad_tpsa_setm(t, l, m, v)
end

function M.getm(t, m, l, res)
  -- m should be a t.mono_t of length l
  res = clib.mad_tpsa_getm(t, l, m)
  return res
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
