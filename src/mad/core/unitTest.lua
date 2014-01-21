local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local LuaUnit = require"mad.test.luaUnit"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

call = function (_, moduleToRunTable)
	LuaUnit:run(moduleToRunTable)
end

-- end ------------------------------------------------------------------------
return M
