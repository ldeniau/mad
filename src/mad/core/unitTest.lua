local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local LuaUnit = require"mad.test.luaUnit"

-- module ---------------------------------------------------------------------

local call = function (_, module_list)
	LuaUnit:run(module_list)
end

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)

mt.__call = function (...)
	return call(...)
end

-- end ------------------------------------------------------------------------
return M
