local ffi = require('ffi')
local setmetatable, tonumber, type, typeof = setmetatable, tonumber, type, ffi.typeof

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local yangLib = ffi.load(PATH .. '/tpsa-yang/libtpsa-yang.so')

ffi.cdef[[
  typedef unsigned int TNVND;
  typedef unsigned int TVEC;

  // this should be called before any other ad_* function and
  // followed by call to ad_reserve
  // nv = number of variables, no = highest order of TPSA
  void ad_init_(const TNVND *nv, const TNVND *no);

  void ad_reserve_(const TVEC *n);    // reserve space for n TPSA vectors
  void ad_fini_();                    // free resources

  // allocate / free space for 1 TPSA vector
  void ad_alloc_(      TVEC *idx);     // idx returns index of new TPSA
  void ad_free_ (const TVEC *idx);     // idx specifies which TPSA to free

  // copies from TPSA at isrc to the TPSA at idst
  void ad_copy_(const TVEC *isrc, const TVEC *idst);

  // set / retrieve coefficient value x of monomial c (size n) from TPSA idx
  // c = {1, 0, 2} -> x * z ^ 2
  void ad_pek_  (const TVEC *idx, int *c, size_t *n, double *x);
  void ad_pok_  (const TVEC *idx, int *c, size_t *n, double *x);
  void ad_const_(const TVEC *idx, const double *r);  // sets the constant term

  // binary operations
  void ad_mult_ (const TVEC *ivlhs, const TVEC *ivrhs, TVEC *ivdst);
  void ad_add_  (const TVEC *ivdst, const TVEC *ivsrc);
  void ad_sub_  (const TVEC *ivdst, const TVEC *ivsrc);
  void ad_div_  (const TVEC *ilhs , const TVEC *irhs, TVEC *idst);

  // binary with const
  void ad_add_const_ (const TVEC *iv, double *c);
  void ad_mult_const_(const TVEC *iv, double *c);
  void ad_div_c_     (const TVEC *iv, const double *c);
  void ad_c_div_     (const TVEC *iv, const double *c, TVEC *ivret);

  void ad_subst_(const TVEC *iv, const TVEC *ibv, const TNVND *nbv,
                 const TVEC *iret);

  void ad_abs_  (const TVEC *iv, double *r);
  void ad_derivative_(const TVEC *isrc, unsigned int *expo, const TVEC *idst);

  // functions
  void ad_sqrt_(const TVEC* iv, const TVEC* iret);
  void ad_exp_ (const TVEC* iv, const TVEC* iret);
  void ad_log_ (const TVEC* iv, const TVEC* iret);
  void ad_sin_ (const TVEC* iv, const TVEC* iret);
  void ad_cos_ (const TVEC* iv, const TVEC* iret);


  void ad_print_(const TVEC *iv);
]]

-- all functions work with pointers, so define their type
-- a pointer to a single value is a length 1 array
local uintPtr  = typeof("unsigned int [1]")
local uintArr  = typeof("unsigned int [?]")
local  intArr  = typeof("         int [?]")
local sizetPtr = typeof("size_t       [1]")
local dblPtr   = typeof("double       [1]")

-- Create pointers to some useful literals
local zero_i, one_i = uintPtr(0),  uintPtr(1)
local zero_d, one_d = dblPtr(0.0), dblPtr(1.0)


local tpsa = { name = "yang", mono_t = intArr }
local MT   = { __index = tpsa }

local initialized = false

local function create(nv, no)
  local t = { nv=sizetPtr(nv), no=no, idx=uintPtr() }
  yangLib.ad_alloc_(t.idx)
  return setmetatable(t, MT)
end

-- should be called before any other tpsa function
function tpsa.init(nv, no)
  local errStr = "Invalid Yang tpsa initializer. Use tpsa.init(nv, no) or tpsa({vars}, no)"

  if     type(nv) == "table"  then nv = #nv
  elseif type(nv) ~= "number" then error(errStr) end
  if     type(no) ~= "number" then error(errStr) end

  if initialized then               -- make sure it is terminated
    yangLib.ad_fini_()              -- before init-ing again
  else
    initialized = true
  end

  yangLib.ad_init_(uintPtr(nv), uintPtr(no))

  -- reserve should be called right after init, so we'll do it here
  local size = 30000                -- to suffice for allocations
  yangLib.ad_reserve_(uintPtr(size))
  return create(nv, no)
end

function tpsa.new(t)
  return create(t.nv[0], t.mo)
end

tpsa.same = tpsa.new

function tpsa.setConst(t, val)
  yangLib.ad_const_(t.idx, dblPtr(val))
end

function tpsa.set(t, mon, val)
  -- mon = array identifying the monomial whose coefficient is set
  -- x1^2 * x3 * x4^3 corresponds to {2, 0, 1, 3}
  local indexes, size = intArr(#mon, mon), sizetPtr(#mon)
  yangLib.ad_pok_(t.idx, indexes, size, dblPtr(val))
end

function tpsa.get(t, mon)
  -- mon = see set
  local indexes, size, val = intArr(#mon, mon), sizetPtr(#mon), dblPtr()
  yangLib.ad_pek_(t.idx, indexes, size, val)

  return tonumber(val[0])
end

function tpsa.cpy(src, dst)
  if not dst then dst = src:new() end
  yangLib.ad_copy_(src.idx, dst.idx)
  return dst
end

function tpsa.abs(t)
  local norm = dblPtr()
  yangLib.ad_abs_(t.idx, norm)
  return norm[0]
end


function tpsa.der(src, var, dst)
  dst = dst or src:same()
  yangLib.ad_derivative_(src.idx, uintPtr(var-1), dst.idx)
  return dst
end

function tpsa.mul(t1, t2, r)
  -- r should be different from t1 and t2
  yangLib.ad_mult_(t1.idx, t2.idx, r.idx)
end

function tpsa.add(t1, t2, t3)
  yangLib.ad_copy_(t1.idx, t3.idx)
  yangLib.ad_add_ (t3.idx, t2.idx)
end

function tpsa.sub(t1, t2, t3)
  yangLib.ad_copy_(t1.idx, t3.idx)
  yangLib.ad_sub_ (t3.idx, t2.idx)
end

function tpsa.compose(a, b, c)
  -- a, b, c should be compatible arrays of TPSAs, starting from 1

  local bIdxs, bSize = uintArr(#b), uintPtr(#b)
  for i=1,#b do bIdxs[i-1] = b[i].idx[0] end

  for i=1,#a do
    yangLib.ad_subst_(a[i].idx, bIdxs, bSize, c[i].idx)
  end
end

-- FUNCTIONS -------------------------------------------------------------------
function tpsa.sin(a, c)
  yangLib.ad_sin_(a.idx, c.idx)
end

function tpsa.cos(a, c)
  yangLib.ad_cos_(a.idx, c.idx)
end

function tpsa.log(a, c)
  yangLib.ad_log_(a.idx, c.idx)
end

function tpsa.exp(a, c)
  yangLib.ad_exp_(a.idx, c.idx)
end

function tpsa.sqrt(a, c)
  yangLib.ad_sqrt_(a.idx, c.idx)
end

function tpsa.destroy(t)
  yangLib.ad_free_(t.idx)
end

function tpsa.print(t)
  yangLib.ad_print_(t.idx)
end

-- OVERLOADING -----------------------------------------------------------------
function MT.__add(a,b)
  local c
  error("UNIMPLEMENTED")
  if type(a) == "number" then
    c = b:cpy()
    yangLib.ad_mult_const_(c.idx, dblPtr(-1))
    yangLib.ad_add_const_(c.idx, dblPtr(a))
  elseif type(b) == "number" then
    c = a:cpy()
    yangLib.ad_add_const_(c.idx, dblPtr(b))
  elseif type(a) == type(b) then
    c = a:same()
    tpsa.sub(a, b, c)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__sub(a,b)
  local c
  if type(a) == "number" then
    c = b:cpy()
    yangLib.ad_mult_const_(c.idx, dblPtr(-1))
    yangLib.ad_add_const_(c.idx, dblPtr(a))
  elseif type(b) == "number" then
    c = a:cpy()
    yangLib.ad_add_const_(c.idx, dblPtr(-b))
  elseif type(a) == type(b) then
    c = a:same()
    tpsa.sub(a, b, c)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__mul(a,b)
  local c
  if type(a) == "number" then
    c = b:cpy()
    yangLib.ad_mult_const_(c.idx, dblPtr(a))
  elseif type(b) == "number" then
    c = a:cpy()
    yangLib.ad_mult_const_(c.idx, dblPtr(b))
  elseif type(a) == type(b) then
    c = a:same()
    yangLib.ad_mult_(a.idx, b.idx, c.idx)
  else
    error("Incompatible operands")
  end
  return c
end

function MT.__div(a,b)
  local c
  if type(a) == "number" then
    c = b:same()
    yangLib.ad_c_div_(b.idx, dblPtr(a), c.idx)
  elseif type(b) == "number" then
    c = a:cpy()
    yangLib.ad_div_c_(c.idx, dblPtr(b))
  elseif type(a) == type(b) then
    c = a:same()
    yangLib.ad_div_(a.idx, b.idx, c.idx)
  else
    error("Incompatible operands")
  end
  return c
end


-- interface for benchmarking --------------------------------------------------

function tpsa.getm(t, m, l, res)
  -- lower level interface; m is a t.mono_t of length nv (i.e. an intArr)
  yangLib.ad_pek_(t, m, l, res)
  return res[0]
end

function tpsa.der_raw(t_in, v, t_out)
  yangLib.ad_derivative_(t_in, uintPtr(v), t_out)
end

function tpsa.compose_raw(sa,ma,sb,mb,sc,mc)
  for i=0,sa-1 do
    yangLib.ad_subst_(ma+i, mb, sb, mc+i)
  end
end

return tpsa

