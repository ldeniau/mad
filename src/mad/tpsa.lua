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

-- locals ----------------------------------------------------------------------

local getmetatable, setmetatable = getmetatable, setmetatable
local type, ipairs, concat = type, ipairs, table.concat
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

-- functions -------------------------------------------------------------------

--------------
-- U utils

local function fun_true() return true end

--------------
-- M monomials

local function mono_val(l, n)
  local a = {}
  for i=1,l do a[i] = n end
  return a
end

local function mono_cpy(a)
  local b = {}
  for i=1,#a do b[i] = a[i] end
  return b
end

local function mono_cat(a)
  local b = {}
  for i=1,#a do
    local ai = a[i]
    for j=1,#ai do b[i] = ai[j] end
  end
  return b
end

local function mono_max(a)
  local m = 0
  for i=1,#a do if a[i]>m then m = a[i] end end
  return m
end

local function mono_sum(a)
  local s = 0
  for i=1,#a do s = s + a[i] end
  return s
end

local function mono_acc(a)
  local s = mono_cpy(a)
  for i=#s-1,1,-1 do s[i] = s[i] + s[i+1] end
  return s
end

local function mono_equ(a,b)
  for i=1,#a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

local function mono_leq(a,b)
  -- partial order relation ({3,0,0} <= {1,1,0})
  for i=#a,1,-1 do
    if     a[i] < b[i] then return true
    elseif a[i] > b[i] then return false
    end
  end
  return true
end

local function melem_leq(a,b)
  for i=1,#a do
    if a[i] > b[i] then return false end
  end
  return true
end

local function mono_add(a,b)
  local c = {}
  for i=1,#a do c[i] = a[i]+b[i] end
  return c
end

local function mono_isvalid(m, a, o, f)
  return mono_sum(m) <= o and melem_leq(m,a) and f(m,a)
end

----------------
-- P polynomials

-- slow but simple... (could be much faster using SSE/AVX intrinsics)
local function poly_mul(a,b,c, start,stop,D)
  local T, O, A, o, f, index = D.To, D.To.o, D.A, D.O, D.F, D.index
  for ia=start,stop do
    for ib=start,ia do
      if O[ia]+O[ib] > o then break end
      local m = mono_add(T[ia],T[ib])  -- _mm_adds_epi8  (16) or _mm256_adds_epi8  (32)
      if mono_isvalid(m,A,O,f) then    -- _mm_cmpgt_epi8 (16) or _mm256_cmpgt_epi8 (32)
        local ic = index(m)
        c[ic] = c[ic] + a[ia]*b[ib]
        if ia ~= ib then c[ic] = c[ic] + a[ib]*b[ia] end
      end
    end
  end
end

local function hpoly_sym_mul(a, b, c, l, iao, ibo)
  for ial=1,#l do -- row
    for ibl=1,#l[ial] do -- col
      local ia, ib, ic = ial+iao, ibl+ibo, l[ial][ibl]
      if ic > 0 then
        c[ic] = c[ic] + a[ia]*b[ib] + a[ib]*b[ia]
      end
    end
  end
end

local function hpoly_asym_mul(a, b, c, l, iao, ibo)
  for ial=1,#l do -- row
    for ibl=1,#l[ial] do -- col
      local ia, ib, ic = ial+iao, ibl+ibo, l[ial][ibl]
      if ic > 0 then
        c[ic] = c[ic] + a[ia]*b[ib]
      end
    end
  end
end

local function hpoly_diag_mul(a, b, c, l, iao, ibo)
  local si = l.si
  for j=1,#si do
    local ia, ib, ic = j+iao, j+ibo, si[j]
    if ic > 0 then
      c[ic] = c[ic] + a[ia]*b[ib]
    end
  end
end

local function poly_mul2(a, b, c, D)
  local L, p = D.L, D.To.ps

  -- init remaining coefs
  local pe = c._T.D.To.pe
  for i=#c+1,pe[c._mo] do c[i] = 0 end

  for oc=2,c._mo do -- orders of c (// loop)
    local ho = oc/2
    for j=1,ho do
      local oa, ob = oc-j, j
      if a._NZ[oa] and b._NZ[ob] and
         a._NZ[ob] and b._NZ[oa] then
        c._NZ[oc] = true
        hpoly_sym_mul(a, b, c, L[oa][ob], p[oa]-1, p[ob]-1)
      elseif a._NZ[oa] and b._NZ[ob] then
        c._NZ[oc] = true
        hpoly_asym_mul(a, b, c, L[oa][ob], p[oa]-1, p[ob]-1)
      elseif a._NZ[ob] and b._NZ[oa] then
        c._NZ[oc] = true
        hpoly_asym_mul(b, a, c, L[oa][ob], p[oa]-1, p[ob]-1)
      end
    end

    if a._NZ[ho] and b._NZ[ho] then
      hpoly_diag_mul(a, b, c, L[ho][ho], p[ho]-1, p[ho]-1)
    end
  end
end

------------------
-- T lookup tables

local function find_index(T, a, start, stop)
  local s1, s2 = start or 1, stop or #T

  for i=s1,s2 do -- TODO: use binary search
    if mono_equ(a, T[i]) then return i end
  end

  io.write('\n')
  M.print_mono(a,'\n')
  M.print_table(T)
  error("monomial not found in table")
end

local function find_index_bin(T, m, start, stop)
  local s1, s2 = start or 1, stop or #T
  local count, i, step = s2-s1+1, 0, 0

  while count > 1 do
    step = floor(count*0.5)
    i = s1+step
    if not mono_leq(T[i], m) then
      count = step
    else
      s1 = i
      count = count-step
    end
  end

  if mono_equ(T[s1], m) then
    return s1
  else
    io.write('\n')
    M.print_mono(m,'\n')
    M.print_table(T)
    error("monomial not found in table, BS")
  end
end

local function nxt_by_unk(a, i, j)
  local b, jj = mono_val(#a, 0), j
  for k=i,#a do
    b[k] = a[k]
    jj = jj - a[k]
    if jj <= 0 then
      if jj < 0 then b[k] = b[k] + jj end
      break
    end
  end
  return b
end

local function nxt_by_var(a,m,o,f)
  for i=1,#a do
    a[i] = a[i]+1
    if mono_isvalid(a,m,o,f) then
      return true
    end
    a[i] = 0
  end
  return false
end

-- TODO: nxt_by_ord, use iterative monomial product

local function table_by_vars(o,m,f)
  local a = mono_val(#m, 0)
  local v = { o={ [0]=0 }, i={ [0]=0 }, [0]=mono_cpy(a) }
  while nxt_by_var(a,m,o,f) do
    v[#v+1] = mono_cpy(a)
    v.o[#v] = mono_sum(a)
  end
  return v
end

-- TODO: build monomials by product instead Tv lookup
local function table_by_ords(o,a)
  local v = { o={[0]=0}, i={[0]=0}, ps={[0]=0}, pe={[0]=0}, [0]=a[0] }
  for i=1,o do
    v.ps[i]   = #v+1
    v.pe[i-1] = #v
    for j=1,#a do
      if a.o[j] == i then
        v[#v+1] = a[j]
        v.o[#v] = i
        v.i[#v] = j
        a.i[j]  = #v
      end
    end
  end
  v.pe[o] = #v
  return v
end

local function makeFirstOrder(t)
  local nv = #t[0]
  t.ps[1], t.pe[1] = 1, nv
  for i=1,nv do
     t[i], t.o[i] = {}, 1
     for j=1,nv do
        if i==j then t[i][j] = 1
        else         t[i][j] = 0 end
     end
  end
end

function M.table_by_ords2(o, a, tv, f)
  local t = { o={[0]=0}, i={[0]=0}, ps={[0]=0}, pe={[0]=0}, [0]=tv[0] }
  makeFirstOrder(t)

  local j
  for ord=2,o do
    for i=1,#a do
      j = t.ps[ord-1]

      repeat
        local m = mono_add(t[i], t[j])
        if mono_isvalid(m, a, o, f) then
          t[#t+1] = m
          t.o[#t] = ord
        end
        j = j+1
      until m[i] > a[i] or m[i] >= ord

    end
    t.ps[ord]   = j
    t.pe[ord-1] = j-1
  end

  for mi=0,#t do
    local i = find_index_bin(tv, t[mi], 0)
    tv.i[i] = mi
  end

  return t
end

-- unit test
local function table_check(D)
  local a, H, Tv, To, index = D.A, D.H, D.Tv, D.To, D.index

  if D.Nc~= #Tv                        then return 1e6+0 end
  for i=2,#a do
    if H[i][1] ~= (H[i-1][a[i-1]+1] and H[i-1][a[i-1]+1] or H[i-1][a[i-1]]+1)
                                       then return 1e6+i end
  end
  for i=1,#D.Tv do
    if To.i[Tv.i[i]] ~= i              then return 2e6+i end
    if index(To[i])  ~= i              then return 3e6+i end
    if not mono_equ(To[Tv.i[i]],Tv[i]) then return 4e6+i end
    if not mono_equ(To[Tv.i[i]],Tv[i]) then return 5e6+i end
  end
  return 0
end

local function set_T(D)
  D.Tv = table_by_vars(D.O, D.A, D.F)
  D.To = table_by_ords(D.O, D.Tv)
  D.Nc = #D.Tv
end

--------------------
-- H indexing matrix

local function index_H(H, a)
  local s, I = 0, 0
  for i=#a,1,-1 do
    I = I + H[i][s + a[i]] - H[i][s]
    s = s + a[i]
  end
  return I
end

local function index_T(D)
  local H, T = D.H, D.Tv.i
  return function (a) return T[ index_H(H,a) ] end
end

local function clear_H(D)
  local a, o, H = D.A, D.O, D.H
  local sa = mono_acc(a)

  for i=1,#a do -- variables
    for j=min(sa[i],o)+1,#H[i] do
      H[i][j] = nil
    end
  end
end

local function solve_H(D)
  local a, o, Tv, H = D.A, D.O, D.Tv, D.H
  local sa = mono_acc(a)

  -- solve system of equations
  for i=#a-1,2,-1 do -- variables
    for j=a[i]+2,min(sa[i],o) do -- orders (unknown)
      -- solve the linear (!) equation of one unknown
      local b    = nxt_by_unk(a,i,j)      -- build monomial for last unkown of H
      local idx0 = index_H(H,b)           -- this makes the indexing equation linear
      local idx1 = find_index(Tv,b,idx0)  -- is linear search slow?
      H[i][j] = idx1 - idx0
    end
  end
end

local function build_H(D)
  local a, o, Tv, H = D.A, D.O, D.Tv, {}

  -- minimal constants for first row
  H[1] = { [0]=0 }
  for j=1,o+1 do -- orders
    H[1][j] = j
  end

  -- remaining rows
  for i=2,#a do -- variables
    H[i] = { [0]=0 }

    -- initial congruence from Tv
    for j=1,#Tv do -- monomials
      if Tv[j][i] ~= Tv[j-1][i] then
        H[i][#H[i]+1] = j
        if Tv[j][i] == 0 then break end
      end
    end

    -- complete row with zeros
    for j=#H[i]+1,o+1 do -- orders
      H[i][j] = 0
    end
  end

  -- close congruence of last var
  H[#a][a[#a]+1] = #Tv+1

  -- update D
  D.H = H
  D.index = index_T(D)
  solve_H(D)
  clear_H(D)
end

local function set_H(D)
  build_H(D)

  -- check consistency (debugging)
  local chk = table_check(D)
  if chk ~= 0 then
    io.write("A= ")   M.print_mono (D.A,'\n')
    io.write("H=")    M.print_table(D.H)
    io.write("Tv= ")  M.print_table(D.Tv);
    io.write("Checking tables consistency... ", chk, '\n')
    error("invalid TPSA descriptor")
  end
end

local function fill_L(oa, ob, D)
  local lc, ps, pe = {}, D.To.ps, D.To.pe
  for ia=ps[oa],pe[oa] do
    local ial = ia-ps[oa]+1 -- shift to 1
    lc[ial] = {}
    for ib=ps[ob],min(ia,pe[ob]) do
      local ibl = ib-ps[ob]+1 -- shift to 1
      lc[ial][ibl] = -1
    end
    if oa==ob then
      lc.si = lc.si or {}
      lc.si[ial] = -1
    end
  end
  return lc
end


local function build_L(oa, ob, D)
  local lc, To, index = fill_L(oa,ob,D), D.To, D.index
  local ps = To.ps
  for ial=1,#lc      do
  for ibl=1,#lc[ial] do
    local ia, ib = ial+ps[oa]-1, ibl+ps[ob]-1
    local m = mono_add(To[ia], To[ib])
    if mono_isvalid(m, D.A, D.O, D.F) then
      if ia ~= ib then
        lc[ial][ibl] = index(m)
      else                   -- symmetric indexes
        lc.si = lc.si or {}
        lc.si[ial] = index(m)
      end
    end
  end
  end
  return lc
end


-- build the table of indexes in polynomials
local function set_L(D)
  local L = {}
  for oc=2,D.O do
    for j=1,oc/2 do -- foreach pair of oa, ob=oc-oa
      local oa, ob = oc-j, j
      L[oa] = L[oa] or {}
      L[oa][ob] = build_L(oa, ob, D)
    end
  end
  D.L = L
end

--------------------
-- D tpsa descriptor

 -- get_desc(key, {var_names}, {var_orders}, max_order, predicate)
local function add_desc(s, n, a, o, f)
  if M.trace then
    io.write("creating descriptor for TPSA { ", s, " }\n")
  end
  local ds = concat(a,',')
  local d = M.D[ds]
  if not d then -- build the descriptor
    d = { A=a, O=o, F=f or fun_true } -- alphas, order and predicate
    set_T(d)
    set_H(d) -- requires Tv
    set_L(d)

    -- do not register the descriptor during benchmark
    if not M.benchmark then M.D[ds] = d end
  end
  M.T[s] = { V=n, D=d }
end

 -- get_desc({var_names}, {var_orders}, max_order, predicate)
local function get_desc(n, o, m, f)
  -- build the key (string) from var_names and var_orders
  local s = concat(n,',') .. ':' .. concat(o,',')
  if not M.T[s] then add_desc(s, n, o, m, f) end
  local t = M.T[s]
  -- do not register the descriptor during benchmark
  if M.benchmark then M.T[s] = nil end
  return t
end

-- debugging -------------------------------------------------------------------

function M.print_vect(a, term)
  local s = not a[0] and 1 or 0

  io.write(string.format("[ %5g ",a[s]))
  for i=s+1,#a do
    io.write(string.format("%5g ",a[i]))
  end
  io.write(" ]\n")
  if term then io.write(term) end
end

function M.print_mono(a, term)
  local s = not a[0] and 1 or 0

  io.write(string.format("[ %2d ",a[s]))
  for i=s+1,#a do
    io.write(string.format("%3d ",a[i]))
  end
  io.write(" ]")
  if term then io.write(term) end
end

function M.print_table(a)
  local s = not a[0] and 1 or 0
  for i=s,#a do
    io.write(string.format("%3d: ",i))
    M.print_mono(a[i])
    if a.o then io.write(string.format("%3d ",a.o[i])) end
    if a.i then io.write(string.format("->%3d ",a.i[i])) end
--    if a.index then io.write(string.format(":%3d ",a.index(a[i]))) end
    io.write("\n")
  end
  if a.p then io.write(" Pi: ") M.print_mono(a.p,'\n') end
end

function M.print_L(D)
  local insp, printf = require "utils.inspect", require "utils.printf"

  local To, L = D.To, D.L
  for oa,_ in pairs(L) do
    for ob,_ in pairs(L[oa]) do
      printf("L[%d][%d] = {\n", oa, ob)
      local l = L[oa][ob]
      for k,v in pairs(l) do
        printf(" [%s] %s\n", k, insp(v))
      end
    end
  end
end

-- methods ---------------------------------------------------------------------

function M:new()
  return setmetatable({ _T=self._T, _NZ={}, _mo=0, [0]=0 }, getmetatable(self));
end

local function same(self)
  local a = self:new()
  a._mo = self._mo
  for o=1,self._mo do a._NZ[o] = self._NZ[o] end
  return a
end

function M:cpy()
  local a, pe = same(self), self._T.D.To.pe
  for i=0,pe[self._mo] do a[i] = self[i] end
  return a
end

function M.getCoeff(t, m)
  if type(m) == "number" then
    return t[m] or 0
  else
    return t[t._T.D.index(m)] or 0
  end
end

function M.setCoeff(t, m, v)
  local D = t._T.D
  local o, i = D.To.o, D.index(m)
  if not t._NZ[o[i]] and v~=0 then
    t._NZ[o[i]] = true
    t._mo = max(t._mo, o[i])
    local ps, pe = D.To.ps, D.To.pe
    for i=ps[t._mo],pe[t._mo] do t[i] = 0 end
  end
  t[i] = v
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

function M.concat(a, b)
  local c, To = {}, b[1]._T.D.To
  for i=1,#b do
    c[i] = b[i]:new()
    local t = b[i]:new()
    t[0] = 1
    for m=0,#To do
      if b[i][m] and b[i][m] ~= 0 then
        for v=1,#To[m] do
          t = a[v]:pow(To[m][v]) * t
        end
        t = b[i][m] * t
      end
    end
    c[i] = c[i] + t
  end
  return c
end



-- metamethods -----------------------------------------------------------------

function M.__add(a, b)
  local c

  if type(a) == "number" then
    c = b:cpy(); c[0] = a+b[0]
  elseif type(b) == "number" then
    c = a:cpy(); c[0] = a[0]+b
  elseif a._T == b._T then
    if #a > #b then a, b = b, a end -- swap
    c = b:new()
    c[0] = a[0]+b[0]
    local pe = a._T.D.To.pe
    for i=1                    ,min(pe[a._mo],#a) do c[i] = a[i]+b[i] end -- // loop
    for i=min(pe[a._mo]+1,#a+1),min(pe[b._mo],#b) do c[i] =      b[i] end -- // loop

    for o=1,max(a._mo,b._mo) do c._NZ[o] = a._NZ[o] or b._NZ[o] end
  else
    error("invalid or incompatible TPSA")
  end

  return c
end

function M.__sub(a, b)
  local c

  if type(a) == "number" then
    c = b:cpy(); c[0] = a-b[0]
  elseif type(b) == "number" then
    c = a:cpy(); c[0] = a[0]-b
  elseif a._T == b._T then
    if #a <= #b then
      c = b:new()
      for i=0,   #a do c[i] = a[i]-b[i] end -- // loop
      for i=#a+1,#b do c[i] =     -b[i] end -- // loop
    else
      c = a:new()
      for i=0   ,#b do c[i] = a[i]-b[i] end -- // loop
      for i=#b+1,#a do c[i] = a[i]      end -- // loop
    end
    for o=1,max(a._mo,b._mo) do c._NZ[o] = a._NZ[o] or b._NZ[o] end
  else
    error("invalid or incompatible TPSA")
  end

  return c
end

function M.__mul(a, b)
  local c

  if type(a) == "number" then
    c = same(b)
    for i=0,#b do c[i] = a*b[i] end -- // loop
  elseif type(b) == "number" then
    c = same(a)
    for i=0,#a do c[i] = b*a[i] end -- // loop
  elseif a._T == b._T then
    if #a > #b then a, b = b, a end -- swap
    c = b:new()

    local a0, b0 = a[0], b[0]
    c[0] = a0*b0
    for i=1   ,#a do c[i] = a0*b[i] + b0*a[i] end -- // loop
    for i=#a+1,#b do c[i] = a0*b[i]           end -- // loop

    c._NZ[1] = true
    c._mo = min(a._mo+b._mo, c._T.D.O)

    -- order >= 2
    if c._T.D.O >=2 then
      poly_mul2(a,b,c, c._T.D) -- // loops
    end
  else
    error("invalid or incompatible TPSA")
  end

  return c
end

function M.__div(a, b)
  local c

  if type(a) == "number" then
    error("TPSA division not yet implemented")
  elseif type(b) == "number" then
    c = a:new(); b = 1/b
    for i=1,#a do c[i] = b*a[i] end -- // loop
  elseif a._T == b._T then
    error("TPSA division not yet implemented")
  else
    error("invalid or incompatible TPSA")
  end

  return c
end


-- constructors of tpsa:
--   tpsa({var_names}, max_order)
--   tpsa({var_names}, {var_orders})
--   tpsa({var_names}, {var_orders}, max_order)
--   tpsa({var_names}, {var_orders}, {{partial_max_orders}})


function MT:__call(n,o,m,f)
  if type(o) == "number" then                          -- ({var_names}, max_order)
    o, m = mono_val(#n,o), o
  elseif is_list(o) and not m then                     -- ({var_names}, {var_orders})
       m = mono_max(o)
  end

  if type(m) == "number" and is_list(o) then           -- ({var_names}, {var_orders}, max_order)
    self.__index = self  -- inheritance
    return setmetatable({ _T=get_desc(n,o,m,f), _NZ={}, _mo=0, [0]=0 }, self); -- _T is {var_names, descriptor}
  end

  error ("invalid tpsa constructor argument, tpsa({var_names}, {var_orders}, {cpl_orders}) expected")
end

-- tests -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M
