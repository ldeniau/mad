local tpsa = require"lib.tpsaFFI"

local M = {}  -- this module

local function make_tpsa(args)
  if not args.id or args.id < 1 or args.id > #args.v then error("Invalid id") end

  local t = tpsa.init(args.x, args.dx, args.k, args.dk)
  return t:new(args.x[args.id])
end


function M.make_map(args)
  local m = {}
  local v, x = args.v, args.x

  if #v ~= #x then error("v and x differ") end
  for i=1,#v do
    if x[i] > 0 then
      args.id = i
      m[v[i]] = make_tpsa(args)
    else
      m[v[i]] = 0
    end
  end
  return m
end


return M