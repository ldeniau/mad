
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
local type, ipairs, concat, min = type, ipairs, table.concat, math.min
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

----------------
-- P polynomials

-- slow but simple... (could be much faster using SSE/AVX intrinsics)
local function poly_mul(a,b,c, start,stop,D)
  local T, O, A, o, f, index = D.To, D.To.o, D.A, D.O, D.F, D.index
  for ia=start,stop do
    for ib=start,ia do
      if O[ia]+O[ib] > o then break end
      local m = mono_add(T[ia],T[ib])  -- _mm_adds_epi8  (16) or _mm256_adds_epi8  (32)
      if mono_leq(m,A) and f(m,A) then -- _mm_cmpgt_epi8 (16) or _mm256_cmpgt_epi8 (32)
        local ic = index(m)
        c[ic] = c[ic] + a[ia]*b[ib]
        if ia ~= ib then c[ic] = c[ic] + a[ib]*b[ia] end
      end
    end
  end
end

local function poly_mul2(a,b,c, oa, ob, D)
  if oa > ob then a, b, oa, ob = b, a, ob, oa end -- swap

-- TODO: build D.PM (sequence of homo poly mul), D.L (indexes)
  for oc=2,D.O do -- orders of c (// loop)
    local PM = D.PM[oc] -- table of homo-poly to multiply
    for j =1,#PM do
      local oa, ob = PM[j][1], PM[j][2] -- P_oa x P_ob -> P_oc (oc = oa+ob)
      local L = D.L[oa][ob] -- lookup from homo-poly orders to indexes, i.e. {ia,ib,ic}
      for i=1,#L do
        local ia, ib, ic = L[i][1], L[i][2], L[i][3]
        c[ic] = c[ic] + a[ia]*b[ib]
        if ia ~= ib then c[ic] = c[ic] + a[ib]*b[ia] end
      end
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

local function nxt_by_var(a,m,o,f)
  for i=1,#a do
    a[i] = a[i]+1
    if mono_sum(a) <= o and mono_leq(a,m) and f(a,m) then
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
  local v = { o={[0]=0}, i={[0]=0}, p={[0]=0}, [0]=a[0] }
  for i=1,o do
    v.p[i] = #v+1
    for j=1,#a do
      if a.o[j] == i then
        v[#v+1] = a[j]
        v.o[#v] = i
        v.i[#v] = j
        a.i[j]  = #v
      end
    end
  end
  v.p[o+1] = #v+1
  return v
end

-- unit test
local function table_check(D)
  local a, H, Tv, To, index = D.A, D.H, D.Tv, D.To, D.index

  if D.N ~= #Tv                        then return 1e6+0 end
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
  D.N  = #D.Tv
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

      -- build the special monomial that makes the equation linear
      local b, jj = mono_val(#a, 0), j
      for k=i,#a do
        b[k] = a[k]
        jj = jj - a[k]
        if jj <= 0 then
          if jj < 0 then b[k] = b[k] + jj end
          break
        end
      end

      -- solve the linear (!) equation of one unknown
      local idx0 = index_H(H,b)
      local idx1 = find_index(Tv,b,idx0)
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
    set_H(d) -- require Tv
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

-- methods ---------------------------------------------------------------------

function M.print_vect(a, term)
  local s = not a[0] and 1 or 0

  io.write(string.format("[ %5g ",a[s]))
  for i=s+1,#a do
    io.write(string.format("%5g ",a[i]))
  end
  io.write(" ]")
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

function M:cpy()
  local a = setmetatable({ _T=self._T }, getmetatable(self))
  for i=1,#self do a[i] = self[i] end -- // loop
  return a
end

function M.__add(a, b)
  local c

  if type(a) == "number" then
    c = { _T = b._T, [0] = a+b[0] }
    for i=1,#b do c[i] = a+b[i] end -- // loop
  elseif type(b) == "number" then
    c = { _T = a._T, [0] = a[0]+b }
    for i=1,#a do c[i] = a[i]+b end -- // loop
  elseif a._T == b._T then
    c = { _T = a._T }
    if #a > #b then a, b = b, a end -- swap
    for i=0,   #a do c[i] = a[i]+b[i] end -- // loop
    for i=#a+1,#b do c[i] =      b[i] end -- // loop
  else
    error("invalid or incompatible TPSA")
  end

  return c
end

function M.__sub(a, b)
  local c

  if type(a) == "number" then
    c = { _T = b._T, [0] = a-b[0] }
    for i=1,#b do c[i] = -b[i] end -- // loop
  elseif type(b) == "number" then
    c = { _T = a._T, [0] = a[0]-b }
    for i=1,#a do c[i] =  a[i] end -- // loop
  elseif a._T == b._T then
    c = { _T = a._T }
    if #a <= #b then
      for i=0,   #a do c[i] = a[i]-b[i] end -- // loop
      for i=#a+1,#b do c[i] =     -b[i] end -- // loop
    else
      for i=0,   #b do c[i] = a[i]-b[i] end -- // loop
      for i=#b+1,#a do c[i] = a[i]      end -- // loop
    end
  else
    error("invalid or incompatible TPSA")
  end

  return c
end

function M.__mul(a, b)
  local c

  if type(a) == "number" then
    c = { _T = b._T }
    for i=0,#b do c[i] = a*b[i] end -- // loop
  elseif type(b) == "number" then
    c = { _T = a._T }
    for i=0,#a do c[i] = a[i]*b end -- // loop
  elseif a._T == b._T then
    c = { _T = a._T }
    if #a > #b then a, b = b, a end -- swap
    -- order 0
    local a0, b0 = a[0], b[0]
    c[0] = a0*b0
    -- order 1
    local n = c._T.D.N
    for i=1,   #a do c[i] = a0*b[i] + b0*a[i] end -- // loop
    for i=#a+1,#b do c[i] = a0*b[i]           end -- // loop
    for i=#b+1, n do c[i] = 0                 end -- // loop
    -- order >= 2
    local o = c._T.D.O
    if o >= 2 then
      local p = a._T.D.To.p -- starting index of orders
      poly_mul(a,b,c, p[1], p[o+1]-1, c._T.D) -- // loops
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
    c = { _T = a._T }
    for i=1,#a do c[i] = a[i]/b end -- // loop
  elseif a._T == b._T then
    error("TPSA division not yet implemented")
  else
    error("invalid or incompatible TPSA")
  end

  return c
end

-- metamethods -----------------------------------------------------------------

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
    return setmetatable({ _T=get_desc(n,o,m,f) }, self); -- _T is {var_names, descriptor}
  end

  error ("invalid tpsa constructor argument, tpsa({var_names}, {var_orders}, {cpl_orders}) expected")
end

-- tests -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M