local tpsa = require"lib.tpsaFFI"

local M = {}  -- this module
local MT = { __index=M }

-- {v={'x','px'}, mo={2,2} [, vo={3,3}] [, ko={1,1}] [, dk=2]}
function M.make_map(args)
  assert(args and args.v and args.mo and #args.v == #args.mo)
  local m = {}
  args.vo = args.vo or args.mo
  m._desc = tpsa.get_desc(args)
  for i=1,#args.mo do
    if args.mo[i] == 0 then
      m[args.v[i]] = 0
    else
      m[args.v[i]] = tpsa.allocate(m._desc,args.mo[i])
    end
  end

  return setmetatable(m,MT)
end

function M:to(ord)
  tpsa.gtrunc(self._desc,ord)
end


return M