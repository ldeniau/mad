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

-- descriptors of all tpsa
M.D = {} -- descriptor
M.T = {} -- descriptor with named vars

-- initialize FFI
local PATH = (...):match("(.+)%.[^%.]+$") or (...) -- current path
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local clib = ffi.load(PATH .. "/../lib/tpsa-ffi/libtpsa-ffi.so")

local static_dcl = [[
typedef struct tpsa   tpsa_t;
typedef unsigned char mono_t;
typedef struct desc   desc_t;
typedef unsigned int  bit_t;
typedef double        num_t;

struct tpsa { // warning: must be kept identical to LuaJit definition
  desc_t *desc;
  int     mo;
  bit_t   nz;
  num_t   coef[?];
};

tpsa_t* tpsa_new(desc_t *d);
int     tpsa_get_nc(desc_t *d);
tpsa_t* tpsa_init(tpsa_t *t, desc_t *d);
void    tpsa_cpy(tpsa_t *src, tpsa_t *dst);
void    tpsa_clr(tpsa_t *t);
void    tpsa_del(tpsa_t* t);
void    tpsa_print(const tpsa_t *t);

void    tpsa_set_coeff(tpsa_t *t, int n, mono_t *m, num_t v);
void    tpsa_set_const(tpsa_t *t, num_t v);
num_t   tpsa_get_coeff(tpsa_t *t, int n, mono_t *m);
int     tpsa_mul(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);

desc_t* tpsa_get_desc      (int nv, mono_t *var_ords, mono_t mo);
desc_t* tpsa_get_desc_knobs(int nv, mono_t *var_ords, mono_t mvo,
                            int nk, mono_t *knb_ords, mono_t mko);
void    tpsa_del_desc(desc_t *d);
]]

ffi.cdef(static_dcl)

local mono_t  = typeof("mono_t [?]")
local desc_t  = typeof("desc_t    ")
local char_arr= typeof("char   [?]")
local tpsa_t  = typeof("tpsa_t    ")

-- functions -------------------------------------------------------------------

local function printf(s, ...)  -- TODO: put this somewhere and import it
  io.write(s:format(...))
end

function M:new(c_side)
  if c_side then
    local t = ffi.gc(clib.tpsa_new(self.desc), clib.tpsa_del)
    return t
  end
  local nc = clib.tpsa_get_nc(self.desc)
  local t  = tpsa_t(nc)
  clib.tpsa_init(t, self.desc)
  return t
end

function M.cpy(src, dst)
  if not dst then dst = src:new(true) end
  clib.tpsa_cpy(src, dst)
  return dst
end

function M.setCoeff(t, m, v)
  clib.tpsa_set_coeff(t, #m, mono_t(#m, m), v)
end

function M.setConst(t, v)
  clib.tpsa_set_const(t, v)
end

function M.getCoeff(t, m)
  return tonumber(clib.tpsa_get_coeff(t, #m, mono_t(#m,m)))
end


-- interface for benchmarking
function M.init(var_names, mo)
  local ords = {}
  for i=1,#var_names do ords[i] = mo end
  return M(false, ords, mo)
end

M.same = M.new

function M.mul(a, b, c)
  -- c should be different from a and b
  return clib.tpsa_mul(a,b,c)
end


-- debugging -------------------------------------------------------------------

M.print = clib.tpsa_print

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
--   tpsa(C_side, {var_orders}, max_var_order)
--   tpsa(C_side, {var_orders}, max_var_order,
--                {knb_orders}, max_knb_order)
--   C_side: nil/false to alloc on lua side; true to alloc on C side

function MT:__call(c_side, var_ords, mvo, knb_ords, mko)
  local err, knobs = false, false
  if not is_list(var_ords) or not mvo                                 then err = true
  elseif knb_ords and (not is_list(knb_ords) or not mko or mvo > mko) then err = true
  else
    -- no problem, continue building
    local d
    local nv, vo = #var_ords, mono_t(#var_ords, var_ords)
    if knb_ords then
      local nk, ko = #knb_ords, mono_t(#knb_ords, knb_ords)
      d = clib.tpsa_get_desc_knobs(nv, vo, mvo, nk, ko, mko)
    else
      d = clib.tpsa_get_desc(nv, vo, mvo)
    end

    if not M._mt_is_set then
      self.__index = self
      ffi.metatype("tpsa_t", self)
      M._mt_is_set = true
    end
    if c_side then
      return ffi.gc(clib.tpsa_new(d), clib.tpsa_del)
    else
      local nc = clib.tpsa_get_nc(d)
      local t  = tpsa_t(nc)
      clib.tpsa_init(t, d)
      return t
    end
  end

  error ("invalid tpsa constructor argument, tpsa(C_side, {var_orders}, "..
           "max_var_order, {knb_orders}, max_knb_order) expected");
end

-- end ------------------s-------------------------------------------------------
return M
