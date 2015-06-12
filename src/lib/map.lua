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
    local K   = tbl[V][key] and V or T
    local var = tbl[K][key]

    if var == nil then
      tbl[K][#tbl[K]+1] = key           -- save the name
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

function M.clear(tbl)
  tbl = tbl[T]
  for i,k in ipairs(tbl) do
    tbl[k]:set_tmp():release()
    tbk[i] = nil
  end
end

function M.print_tmp(tbl)
  tbl = tbl[T]
  for i,k in ipairs(tbl) do
    print(i, k, tbl[k])
  end
end

function M.print(tbl)
  for _,name in ipairs(tbl[V]) do
    local var = tbl[V][name]
    io.write(name, ': ')
    if type(var) == 'number' then
      print(var)
    else
      var:print()
    end
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

local clib = tpsa.clib

function M.track_drift(m, e)
  local t1 = clib.mad_tpsa_new(m.x, clib.mad_tpsa_default)
  local t2 = clib.mad_tpsa_new(m.s, clib.mad_tpsa_same   )

  clib.mad_tpsa_ax2pby2pcz2(1,m.ps, -1,m.px, -1,m.py, t1)  -- ps^2 - px^2 - py^2
  clib.mad_tpsa_axpbypc(2/e.b,m.ps, 1,t1, 1, t1)           -- 1 + 2/e.b*m.ps + ps^2 - px^2 - py^2
  clib.mad_tpsa_invsqrt(t1,e.L, t1)                        -- e.L/sqrt(1 + 2/e.b*m.ps + ps^2 - px^2 - py^2)

  local l_pz = t1

  clib.mad_tpsa_axypbzpc(1,m.px,l_pz, 1,m.x, 0, m.x)     -- x + px*l_pz -> x
  clib.mad_tpsa_axypbzpc(1,m.py,l_pz, 1,m.y, 0, m.y)     -- y + py*l_pz -> y

  clib.mad_tpsa_copy(m.ps, t2)                           -- ps
  clib.mad_tpsa_set0(t2,1,1/e.b)                         -- ps + 1/B
  clib.mad_tpsa_axypbzpc(1,t2,l_pz, 1,m.s, (e.T-1)*e.LD/e.b, m.s) -- s + (ps + 1/e.b)*l_pz -> s

  clib.mad_tpsa_del(t1)
  clib.mad_tpsa_del(t2)
end

function M.track_kick(m, e)
  local dir = (m.dir or 1) * (m.charge or 1)

  local bbxtw = clib.mad_tpsa_new(m.px, clib.mad_tpsa_same)
  local bbytw = clib.mad_tpsa_new(m.py, clib.mad_tpsa_same)
  
  clib.mad_tpsa_scalar(bbxtw, e.bn[e.nmul] or 0)
  clib.mad_tpsa_scalar(bbytw, e.an[e.nmul] or 0)

  if e.nmul > 1 then
    local bbytwt = clib.mad_tpsa_new(m.py, clib.mad_tpsa_same)
    
    for j=e.nmul-1,1,-1 do
      clib.mad_tpsa_axypbvwpc(1,m.x,bbytw, -1,m.y,bbxtw, e.bn[j], bbytwt)
      clib.mad_tpsa_axypbvwpc(1,m.y,bbytw,  1,m.x,bbxtw, e.an[j], bbxtw )
      bbytw, bbytwt = bbytwt, bbytw
    end

    clib.mad_tpsa_del(bbytwt)
  end

  clib.mad_tpsa_axpbypc(1,m.px, -e.L*dir,bbytw, 0, m.px)
  clib.mad_tpsa_axpbypc(1,m.py,  e.L*dir,bbxtw, 0, m.py)

  clib.mad_tpsa_axypbzpc(1,m.ps,m.ps, 2/e.b,m.ps, 1, m.ps)
  clib.mad_tpsa_sqrt(m.ps,m.ps)
  clib.mad_tpsa_set0(m.ps,1,-1)

  clib.mad_tpsa_del(bbytw)
  clib.mad_tpsa_del(bbxtw)
end

return M
