local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
-- The reason for doing it like this is to not have to change too many names within the libs, but not putting them on package.path for the user. This method makes the btd.lua.Test be reachable by btd.lua.Test, instead of lib.btd.lua.Test.
local pkp = package.path
local pkcp = package.cpath
package.cpath = ";;./lib/lua/5.1/?.so;"..package.cpath
package.path = ";;./lib/?.lua;./lib/lua/5.1/?.lua;"..package.path
local LuaUnit = require"btd.lua.Test"()
package.path = pkp
package.cpath = pkcp

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

M.testapi = require"btd.lua.TestApi"



call = function (_, ...)
	print("Setting up tests done.")
	local toRun = require"lang.parser.lua.defs"
	--LuaUnit:run(toRun.test)
	print("Running tests done. (No tests have actually been run)")
end

-- end ------------------------------------------------------------------------
return M
