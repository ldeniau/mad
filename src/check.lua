local M = {}

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

local function fprintf(f, s, ...)  -- TODO: put this somewhere and import it
  f:write(s:format(...))
end


function M.setup(mod, nv, no, filename)
  M.mod = mod
  if not filename then filename = (mod.name or "check") .. ".out" end
  if not M.file then
    M.file = io.open(filename, "w")
  end
  M.To = table_by_ords(nv, no)
  fprintf(M.file, "\n\n=NV= %d, NO= %d =======================", nv, no)
end

function M.tear_down()
  M.file:close()
end


function M.print(t)
  local f, To = M.file, M.To

  fprintf(f, "\nCOEFFICIENT                \tEXPONENTS\n")

  for m=0,#To do
    local v = t:getCoeff(To[m])
    if v ~= 0 then
      fprintf(f, "%20.10E\t", v)
      for mi=1,#To[m] do
        fprintf(f, "%d ", To[m][mi])
      end
      fprintf(f, "\n")
    end
  end
end




return M
