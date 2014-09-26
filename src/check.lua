local M = {}

local function fprintf(f, s, ...)  -- TODO: put this somewhere and import it
  f:write(s:format(...))
end

local min, abs = math.min, math.abs

local function mono_val(l, n)
  local a = {}
  for i=1,l do a[i] = n end
  return a
end

local function mono_add(a,b)
  local c = {}
  for i=1,#a do c[i] = a[i]+b[i] end
  return c
end

local function mono_sum(a)
  local s = 0
  for i=1,#a do s = s + a[i] end
  return s
end

local function melem_leq(a,b)
  for i=1,#a do
    if a[i] > b[i] then return false end
  end
  return true
end

local function mono_isvalid(m, a, o)
  return mono_sum(m) <= o and melem_leq(m,a)
end

local function mono_print(m, file)
  file = file or io.output()
  for mi=1,#m do
    fprintf(file, "%d ", m[mi])
  end
end


function M.fill_ord1(t, nv)
  local m = mono_val(nv, 0)
  t:setCoeff(m, 1.1)
  for i=1,nv do
    m[i] = 1
    t:setCoeff(m, 1.1 + i/10)
    m[i] = 0
  end
end

function M.fill_full(t, no)
  -- t:pow(no)
  local b, r, floor = t:cpy(), t:new(), math.floor
  r:setConst(1)

  while no > 0 do
    if no%2==1 then
      r.mul(r, b, t)
      r, t = t, r
      no = no - 1
    end
    b.mul(b, b, t)
    b, t = t, b
    no = no/2
  end
--  r:print()
  r:cpy(t)
end


local function initMons(nv)
  local t = { ps={ [0]=0, [1]=1 }, pe={ [0]=0, [1]=nv } }

  for i=0,nv do
    t[i] = {}
    for j=1,nv do
      if i==j then t[i][j] = 1
      else         t[i][j] = 0 end
     end
  end

  return t
end

local function table_by_ords(nv, no)
  local t, a = initMons(nv), mono_val(nv, no)

  local j
  for ord=2,no do
    for i=1,nv do
      j = t.ps[ord-1]

      repeat
        local m = mono_add(t[i], t[j])
        if mono_isvalid(m, a, no) then
          t[#t+1] = m
        end
        j = j+1
      until m[i] > a[i] or m[i] >= ord

    end
    t.ps[ord]   = j
    t.pe[ord-1] = j-1
  end
  return t
end


function M.setup(mod, vars, no, filename)
  M.mod, M.vars, M.no = mod, vars, no
  if not filename then filename = (mod.name or "check") .. ".out" end
  if not M.file then
    M.file = io.open(filename, "w")
  end
  M.To = table_by_ords(#vars, no)
  fprintf(M.file, "\n\n=NV= %d, NO= %d =======================", #vars, no)
end

function M.tear_down()
  M.file:close()
end


local function prepare_check(vars, no)
  local mod, To = M.mod, M.To
  if not vars or not no then
    vars, no = M.vars, M.no
  elseif vars ~= M.vars or no ~= M.no then
    To = table_by_ords(#vars, no)
  end

  local berz = require"lib.tpsaBerz"
  local t =  mod.init(vars, no)
  local b = berz.init(vars, no)

  M.fill_ord1(b, #vars)
  M.fill_full(b, no)
  M.fill_ord1(t, #vars)
  M.fill_full(t, no)

  return t, b, To
end

function M.same_coeff(t1, t2, eps, To)
  for m=0,#To do
    local vt, vb = t1:getCoeff(To[m]), t2:getCoeff(To[m])

    -- get the min for computing relative error
    local minV = min(vb,vt) == 0 and 1 or min(vb,vt)

    if abs((vb-vt)/minV) > eps then
      fprintf(io.output(), "\n mono: ")
      mono_print(To[m])
      fprintf(io.output(), "  v%s = %s vBerz = %f (eps = %f)\n",
              M.mod.name, vt, vb, eps)
      t1:print()
      t2:print()
      error("Coefficients differ among libraries")
    end
  end
end


function M.with_berz(eps, vars, no)
  -- cross checks a full tpsa of (nv, no) with a full berz tpsa
  -- if nv, no are not specified then the ones from setup are used

  local mod, t, b, To = M.mod, prepare_check(vars, no)
  eps = eps or 1e-3
  M.same_coeff(t, b, eps, To)
end

function M.print(t)
  local f, To = M.file, M.To

  fprintf(f, "\nCOEFFICIENT                \tEXPONENTS\n")

  for m=0,#To do
    local v = t:getCoeff(To[m])
    if v ~= 0 then
      fprintf(f, "%20.10E\t", v)
      mono_print(To[m], f)
      fprintf(f, "\n")
    end
  end
end


function M.print_all(...)
  local arg = {...}
  for i=1,#arg do M.print(arg[i]) end
end


return M
