
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
local is_list = utils.is_list

-- metatable for the root of all tpsa
local MT = object {}

 -- make the module the root of all tpsa
MT (M)
M.name = 'tpsa'
M.kind = 'tpsa'
M.is_tpsa = true

-- descriptors of all tpsa
local D = {}

-- functions -------------------------------------------------------------------

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

local function mono_accR(a)
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

------------------
-- T lookup tables

local function find_index(T, a, start, stop)
  local s1, s2 = start or 1, stop or #T

  for i=s1,s2 do -- TODO: use binary search
    if mono_equ(a, T[i]) then return i end
  end

  io.write("\n")
  M.print_mono(a)
  M.print_table(T)
  error("monomial not found in table")
end

local function nxt_by_var(a,m,o)
  for i=1,#a do
    a[i] = a[i]+1
    if mono_sum(a) <= o and mono_leq(a,m) then
      return true
    end
    a[i] = 0
  end
  return false
end

-- TODO: nxt_by_ord, use iterative monomial product

local function table_by_vars(o,m)
  local a = mono_val(#m, 0)
  local v = { o={ [0]=0 }, i={ [0]=0 }, [0]=mono_cpy(a) }
  while nxt_by_var(a,m,o) do
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
  v.p[#v.p+1] = #v+1
  return v
end

-- unit test
local function table_check(D)
  local a, H, Tv, To= D.A, D.H, D.Tv, D.To

  if D.N ~= #Tv+1                         then return 1e6+0 end
  for i=2,#a do
    if H[i][1] ~= (H[i-1][a[i-1]+1] and H[i-1][a[i-1]+1] or H[i-1][a[i-1]]+1)
                                          then return 1e6+i end
  end
  for i=1,#D.Tv do
    if To.i[Tv.i[i]]  ~= i                then return 2e6+i end
    if D.index(Tv[i]) ~= i                then return 3e6+i end
    if not mono_equ(To[Tv.i[i]],Tv[i])    then return 4e6+i end
    if not mono_equ(To[Tv.i[i]],Tv[i])    then return 5e6+i end
  end
  return 0
end

local function set_T(D)
  D.Tv = table_by_vars(D.O, D.A)
  D.To = table_by_ords(D.O, D.Tv)
  D.N  = #D.Tv+1
  -- D.check_table = table_check
end

--------------------
-- H indexing matrix

local function index_H(H)
  return function (a)
    local s, I = 0, 0
    for i=#a,1,-1 do
      I = I + H[i][s + a[i]] - H[i][s]
      s = s + a[i]
    end
    return I
  end
end

local function clear_H(D)
  local a, o, H = D.A, D.O, D.H
  local sa = mono_accR(a)

--  io.write(string.format("o=%3d, sa= ", o)) M.print_mono(sa)
  for i=1,#a do -- variables
    for j=math.min(sa[i],o)+1,#H[i] do
      H[i][j] = nil
    end
  end
end

local function solve_H(D)
  local a, o, Tv, H, index = D.A, D.O, D.Tv, D.H, D.index
  local sa = mono_accR(a)

  -- solve system of equations
  for i=#a-1,2,-1 do -- variables
    for j=a[i]+2,math.min(sa[i],o) do -- orders (unknown)

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

--      io.write(string.format("i,j= %3d, %3d, sa=%3d,   b= ", i, j, sa[i])) M.print_mono(b)

      -- solve the linear (!) equation of one unknown
      local idx0 = index(b)
      local idx1 = find_index(Tv,b,idx0)
      H[i][j] = idx1 - idx0

--      io.write(string.format(" idx0=%3d, idx1=%3d\n", idx0, idx1))
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
  D.H, D.index = H, index_H(H)
  solve_H(D)
  clear_H(D)
end

local function set_H(D)
  build_H(D)
  D.set_H = set_H

  -- debugging -- check consistency
  local chk = table_check(D)
  if chk ~= 0 then
    io.write(string.format("A= ")) M.print_mono(D.A)
    print("H=")  ;  t.print_table(D.H)
    print("Tv= ");  t.print_table(D.Tv);
    io.write(string.format("Checking tables consistency... %d\n", chk))
  end
end

--------------------
-- D tpsa descriptor

local function add_desc(s, o, a)
  if M.trace then
    io.write("creating descriptor for TPSA { ", s, " }\n")
  end
  D[s] = { A=a, O=o }
  set_T(D[s])
  set_H(D[s]) -- require Tv
end

local function get_desc(o, a)
  local s = concat(a,',')
  if not D[s] then add_desc(s, o, a) end
  if not M.benchmark then
    return D[s]
  end
  -- for benchmark only: does not register the descriptor
  local d = D[s]
  D[s] = nil
  return d
end

-- methods ---------------------------------------------------------------------

function M.print_vect(a)
  local s = not a[0] and 1 or 0

  io.write(string.format("[ %2d ",a[s]))
  for i=s+1,#a do
    io.write(string.format("%3d ",a[i]))
  end
  io.write(" ]")
end

function M.print_mono(a)
  M.print_vect(a)
  io.write("\n")
end

function M.print_table(a)
  local s = not a[0] and 1 or 0
  for i=s,#a do
    io.write(string.format("%3d: ",i))
    M.print_vect(a[i])
    if a.o then io.write(string.format("%3d ",a.o[i])) end
    if a.i then io.write(string.format("->%3d ",a.i[i])) end
    if a.index then io.write(string.format(":%3d ",a.index(a[i]))) end
    io.write("\n")
  end
  if a.p then M.print_list(a.p) end
end

-- metamethods -----------------------------------------------------------------

-- constructor of tpsa([max_order,] #vars or {var_orders})
function MT:__call(o,a)
  if not a and is_list(o) then                              -- ({var_orders})
    a, o = o, mono_max(o)
  elseif type(o) == "number" and type(a) == "number" then   -- (max_order, #vars)
    a = mono_val(a,o)
  end

  if type(o) == "number" and is_list(a) then                -- (max_order, {var_orders})
    self.__index = self         -- inheritance
    return setmetatable({ _D=get_desc(o,a) }, self);
  end

  error ("invalid tpsa constructor argument, tpsa([max_order,] #vars or {var_orders}) expected")
end

-- tests -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M