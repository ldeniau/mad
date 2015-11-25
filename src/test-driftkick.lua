local tpsa = require"lib.tpsaFFI"
local map = require"lib.map"

local is_number = function(a)
  return type(a) == "number"
end

local sqrt = function(a)
  return is_number(a) and math.sqrt(a) or a:sqrt()
end

local same = function(a, b)
  return not is_number(a) and a:same(b) or a
end

local scalar = function(a, b) -- in place
  if not is_number(a) then
    a:scalar(b)
  else
    a = b
  end
  return a
end

local function track_drift(m, e)
  -- TODO: consider the direction
  m.pz = e.L/sqrt(1 + (2/e.b)*m.ps + m.ps^2 - m.px^2 - m.py^2)
  m.x  = m.x + m.px*m.pz
  m.y  = m.y + m.py*m.pz
  m.s  = m.s + (1/e.b + m.ps)*m.pz - (1-e.T)*e.LD/e.b
end

local function track_kick(m, e)
    local dir = (m.dir or 1) * (m.charge or 1)
    local bbytwt

    m.bbxtw = scalar(m.bbxtw or same(m.px), e.bn[e.nmul] or 0)
    m.bbytw = scalar(m.bbytw or same(m.py), e.an[e.nmul] or 0)
    
    for j=e.nmul-1,1,-1 do
        bbytwt = m.x * m.bbytw - m.y * m.bbxtw + e.bn[j]
      m.bbxtw  = m.y * m.bbytw + m.x * m.bbxtw + e.an[j]
      m.bbytw  = bbytwt
    end

    m.px = m.px - e.L * dir * m.bbytw
    m.py = m.py + e.L * dir * m.bbxtw
    m.ps = sqrt(1 + (2/e.b)*m.ps  + m.ps^2) - 1 -- exact or not exact?
end

if #arg ~= 1 then
  io.write("expecting an input value\n")
  os.exit()
end

local m

if false then
  m = map.make_map{v={'x','px', 'y','py', 's','ps'}, mo={0,0,0,0,0,0}} -- only scalars
  m.x  = 1e-4 -- orbit at origin
  m.y  = 1e-4
  m.s  = 0
  m.px = tonumber(arg[1]) -- transverse momenta
  m.py = tonumber(arg[1])
  m.ps = 1e-6 -- synchronized
else
  m = map.make_map{v={'x','px', 'y','py', 's','ps'}, mo={1,1,1,1,1,1}} -- , mo={2,2,2,2,2,2}} -- mo={1,1,1,1,1,1}}
  m.x:set({0}, 1e-4) -- orbit at origin
  m.y:set({0}, 1e-4)
  m.s:set({0}, 0)
  m.px:set({0}, tonumber(arg[1])) -- transverse momenta
  m.py:set({0}, tonumber(arg[1]))
  m.ps:set({0}, 1e-6)   -- ps: delta in energy
  m.ps:set({1,0,0}, 1)  -- trig d_ps/d_x derivatives
  m.ps:set({0,0,1}, 1)  -- trig d_ps/d_y derivatives
end

m.charge, m.dir = 1, 1

m:print()

local e =  { L=1, b=1, T=1, LD=1 } -- drift
--local e = { L=1, b=1, nmul=2, bn = {0.0, 0.2}, an = {0.0, 0.0} } -- kick

for i=1,1e6 do
--  track_kick(m,e)
-- m:track_kick(e)

  track_drift(m,e)
--  m:track_drift(e)
end

m:print()

print(tpsa.count)

-- m:print_tmp()

-- tracking drifts (lua)
-- numbers:  2.5 sec (1e9 loops)
-- order 1:  3.5 sec (1e6 loops)
-- order 2:  5.2 sec (1e6 loops)
-- order 3:  6.6 sec (1e6 loops)
-- order 4: 10.1 sec (1e6 loops)
-- order 5: 19.2 sec (1e6 loops)
-- order 6: 40.2 sec (1e6 loops)
-- tracking drifts (lua-C)
-- order 1:  0.4 sec (1e6 loops)
-- order 2:  1.3 sec (1e6 loops)
-- order 3:  2.2 sec (1e6 loops)
-- order 4:  3.9 sec (1e6 loops)
-- order 5:  8.3 sec (1e6 loops)
-- order 6: 18.0 sec (1e6 loops)
