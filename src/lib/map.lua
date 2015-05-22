local tpsa = require"lib.tpsaFFI"

local M = {}  -- this module
local V = {}  -- private keys
local D = {}  -- private desc
local MT = {  -- metatable
  __index = function (tbl, key)
    return tbl[V][key] or M[key]
  end,

  __newindex = function (tbl, key, val)
    local var = assert(tbl[V][key], "invalid map variable")
    if type(var) == "number" then
      tbl[V][key] = type(val) == "number" and val or val.coef[0]
    elseif type(val) == "number" then
      tpsa.setConst(var, val)
    else
      tpsa.cpy(val, var)
    end 
  end
}

-- {v={'x','px'}, mo={2,2} [, vo={3,3}] [, ko={1,1}] [, dk=2]}
function M:make_map(args)
  assert(args and args.v and args.mo and #args.v == #args.mo)
  local m = { [V]={} }
  args.vo = args.vo or args.mo
  m[D] = tpsa.get_desc(args)
  for i=1,#args.mo do
    if args.mo[i] == 0 then
      m[V][args.v[i]] = 0
    else
      m[V][args.v[i]] = tpsa.allocate(m[D],args.mo[i])
    end
  end
  return setmetatable(m,MT)
end

function M:to(...)
  local to, mo = -1
  for _,v in ipairs{...} do
    mo = type(v) == "number" and 0 or v.mo
    to = mo > to and mo or to
  end

  tpsa.gtrunc(self[D],to)
end


return M