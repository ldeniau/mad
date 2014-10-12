local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.tspa -- Truncated Power Series Algebra

SYNOPSIS

DESCRIPTION

RETURN VALUES

ERRORS

EXAMPLES

SEE ALSO
  None
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local utils  = require"mad.utils"
local ffi    = require"ffi"

-- locals ----------------------------------------------------------------------

local getmetatable, setmetatable = getmetatable, setmetatable
local sizeof, typeof = ffi.sizeof, ffi.typeof
local type, tonumber, concat = type, tonumber, table.concat
local min, max, floor = math.min, math.max, math.floor
local is_list = utils.is_list

-- metatable for the root of all tpsa
local MT = object {}

 -- make the module the root of all tpsa
MT (M)
M.name = 'tpsa'
M.kind = 'tpsa'
M.is_tpsa = true

-- initialize FFI
local PATH = (...):match("(.+)%.[^%.]+$") or (...) -- current path
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local clib = ffi.load(PATH .. "/../lib/tpsa-ffi/libtpsa-ffi.so")

local static_dcl = [[

// --- types -------------------------------------------------------------------

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

// --- interface ---------------------------------------------------------------

// --- --- DESC ----------------------------------------------------------------

D*    mad_tpsa_desc_new  (int nv, const ord_t var_ords[], ord_t mo);
D*    mad_tpsa_desc_newk (int nv, const ord_t var_ords[], ord_t mvo, // with knobs
                          int nk, const ord_t knb_ords[], ord_t mko);
void  mad_tpsa_desc_del  (struct tpsa_desc *d);

int   mad_tpsa_desc_nc   (const struct tpsa_desc *d);

// --- --- TPSA ----------------------------------------------------------------

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

// -----------------------------------------------------------------------------

]]

ffi.cdef(static_dcl)

local mono_t  = typeof("ord_t[?]")
local desc_t  = typeof("D       ")
local tpsa_t  = typeof("T       ")

-- functions -------------------------------------------------------------------

local function printf(s, ...)  -- TODO: put this somewhere and import it
  io.write(s:format(...))
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


-- interface for benchmarking
function M.init(var_names, mo)
  local ords = {}
  for i=1,#var_names do ords[i] = mo end
  return M(ords, mo)
end

M.same = M.new

function M.mul(a, b, c)
  -- c should be different from a and b
  return clib.mad_tpsa_mul(a,b,c)
end


-- debugging -------------------------------------------------------------------

M.print = clib.mad_tpsa_print

-- metamethods -----------------------------------------------------------------

function M.__mul(a, b)
  local r, rcf, scf

  if type(a) == "number" then
    r = same(b)
    local rc = r._c
    rcf, scf = rc.coef, b._c.coef
    for i=0,rc.desc.nc do rcf[i] = a * scf[i] end
  elseif type(b) == "number" then
    r = same(a)
    local rc = r._c
    rcf, scf = rc.coef, a._c.coef
    for i=0,rc.desc.nc do rcf[i] = b * scf[i] end
  elseif a._T == b._T then
    r = b:new()
    clib.tpsa_mul(a._c, b._c, r._c)
  else
    error("invalid or incompatible TPSA")
  end

  return r
end

function M.pow(a, p)
  local b, r = a:cpy(), 1

  while p>0 do
    if p%2==1 then r = r*b end
    b = b*b
    p = floor(p/2)
  end
  return r
end

-- constructors of tpsa:
--   tpsa({var_orders}, max_var_order)
--   tpsa({var_orders}, max_var_order,
--        {knb_orders}, max_knb_order)

function MT:__call(var_ords, mvo, knb_ords, mko)
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
      self.__index = self
      ffi.metatype("struct tpsa", self)
      M._mt_is_set = true
    end

    return t
  end

  error ("invalid tpsa constructor argument. Use:\n"..
         "\ttpsa({var_orders}, max_var_order, {knb_orders}, max_knb_order)\n");
end

-- end -------------------------------------------------------------------------
return M
