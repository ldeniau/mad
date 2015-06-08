local tpsa = require"lib.tpsaFFI"
local type, insert = type, table.insert

local function mono_sum(m)
  local s = 0
  for i=1,#m do s = s + m[i] end
  return s
end


local M = {}  -- this module
local V = {}  -- private keys
local T = {}  -- temporary keys
local D = {}  -- private desc
local MT = {  -- metatable
  __index = function (tbl, key)
--    io.write("getting ", key, '\n')
    return tbl[V][key] or tbl[T][key] or M[key]
  end,

  __newindex = function (tbl, key, val)
--    io.write("setting ", key, '\n')
    local K = tbl[V][key] and V or T
    local var = tbl[K][key]

    if var == nil then
      insert(tbl[K],key)                     -- save the name
      if type(val) == "number" then
        tbl[K][key] = val               -- create number
      else
        tbl[K][key] = val:set_var()     -- create TPSA
      end

    elseif type(var) == "number" then
      if type(val) == "number" then
        tbl[K][key] = val               -- number -> number
      else
        tbl[K][key] = val.coef[0]       -- TPSA -> number
        val:release()
      end
    elseif type(val) == "number" then
      tpsa.scalar(var, val)             -- number -> TPSA
    else
      tpsa.cpy(val, var)                -- TPSA -> TPSA
      val:release()
    end
  end
}

function M.clear(m)
  for i=1,#m[T] do
    local name = m[T][i]
    m[T][name]:set_tmp():release()
  end
end

function M.print_tmp(m)
  for i=1,#m[T] do
    print(m[T][m[T][i]])
  end
end

-- {v={'x','px'}, mo={3,3} [, vo={2,2}] [, ko={1,1,1} ] [, dk=2]}
-- {v={'x','px'}, mo={3,3} [, vo={2,1}] [, nk=3,ko=1  ] [, dk=2]}
function M.make_map(args)
  assert(args and args.v and args.mo and #args.v == #args.mo)
  local m = { [V]={}, [T]={} }
  args.vo = args.vo or args.mo

  if mono_sum(args.vo) ~= 0 and mono_sum(args.mo) ~= 0 then
    m[D] = tpsa.get_desc(args)
  end

  for i=1,#args.mo do
    m[V][i] = args.v[i]      -- save the var names
    if args.mo[i] == 0 then
      m[V][args.v[i]] = 0
    else
      m[V][args.v[i]] = tpsa.allocate(m[D],args.mo[i])
    end
  end
  return setmetatable(m,MT)
end

function M:to(...)
  if not self[D] then return end
  local to, mo = -1
  for _,v in ipairs{...} do
    mo = type(v) == "number" and 0 or v.mo
    to = mo > to and mo or to
  end

  tpsa.gtrunc(self[D],to)
end

function M.set(m, var, mono, val)
  if type(m[var]) == "number" then
    assert(mono_sum(mono) == 0, "Invalid set for constant var")
    m[var] = val
  else
    m[var]:set(mono, val)
  end
end

function M.get(m, var, mono)
  return type(m[var]) == "number" and assert(mono_sum(mono) == 0, "Invalid get") and m[var]
         or m[var]:get(mono)
end

function M.print(m)
  local write = io.write
  for i=1,#m[V] do
    local name = m[V][i]
    local var  = m[V][name]

    write(name, ': ')
    if type(var) == 'number' then
      print(var)
    else
      var:print()
    end
  end
end

local clib = tpsa.clib_
local t1, t2, t3

function M.track_drift(m, e)
  -- should use ^2 instead of * without speed loss
  local x,   y,  s = m.x,  m.y,  m.s
  local px, py, ps = m.px, m.py, m.ps

  if t1 == nil then
    t1, t2, t3 = x:same(), x:same(), x:same()
  end

--  l_pz = e.L/sqrt(1 + (2/e.b)*m.ps + m.ps^2 - m.px^2 - m.py^2)
--  m.x = m.x + m.px*l_pz
--  m.y = m.y + m.py*l_pz
--  m.s = m.s + (1/e.b + m.ps)*l_pz - (1-e.T)*e.LD/e.b

  -- TODO: set max order for pz and other expression

  clib.mad_tpsa_mul(ps,ps,t1)                           -- ps^2
  clib.mad_tpsa_mul(px,px,t2)                           -- px^2
  clib.mad_tpsa_sub(t1,t2,t3)                           -- ps^2 - px^2
  clib.mad_tpsa_mul(py,py,t2)                           -- py^2
  clib.mad_tpsa_sub(t3,t2,t1)                           -- ps^2 - px^2 - py^2

  clib.mad_tpsa_scale(2/e.b,ps,t2)                      -- 2/e.b*m.ps
  clib.mad_tpsa_seti(t2,0,1+t2.coef[0])                 -- 1 + 2/e.b*m.ps
  clib.mad_tpsa_add(t1,t2,t3)                           -- 1 + 2/e.b*m.ps + ps^2 - px^2 - py^2
--  clib.mad_tpsa_axpbypc(2/e.b,ps, 1,t1, 1, t3)
--  clib.mad_tpsa_invsqrt(e.L,t3,t2)                          -- 1/sqrt(1 + 2/e.b*m.ps + ps^2 - px^2 - py^2) = pz_
  clib.mad_tpsa_invsqrt(t3,t2)                          -- 1/sqrt(1 + 2/e.b*m.ps + ps^2 - px^2 - py^2) = pz_
  clib.mad_tpsa_scale(e.L,t2,t1)                        -- L/sqrt(1 + 2/e.b*m.ps + ps^2 - px^2 - py^2) = pz_

  clib.mad_tpsa_mul(px,t1,t2)                           -- px*pz_
  clib.mad_tpsa_add(x,t2,t3)                            -- x + px*pz_
  clib.mad_tpsa_copy(t3, x)

  clib.mad_tpsa_mul(py,t1,t2)                           -- py*pz_
  clib.mad_tpsa_add(y,t2,t3)                            -- x + py*pz_
  clib.mad_tpsa_copy(t3, y)

  clib.mad_tpsa_copy(ps,t3)                             -- ps
  clib.mad_tpsa_seti(t3,0,1/e.b+t3.coef[0])             -- 1/e.b + ps
--  clib.mad_tpsa_axypbypc(1,t1,t3, 1,t3, -(1-e.T)*e.LD/e.b, s)
  clib.mad_tpsa_mul(t1,t3,t2)                           -- (1/e.b + ps)*pz_
  clib.mad_tpsa_add(ps,t2,t3)                           -- ps + (1/e.b + ps)*pz_
  clib.mad_tpsa_seti(t3,0,t3.coef[0]-(1-e.T)*e.LD/e.b)  -- ps + (1/e.b + ps)*pz_ - (1-e.T)*e.LD/e.b
  clib.mad_tpsa_copy(t3, s)
end

return M
