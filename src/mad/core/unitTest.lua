local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local luaUnit = require"mad.utest.luaUnit"
local module  = require"mad.module"

-- module ---------------------------------------------------------------------
local utest

local call = function (_, module_list)
    utest = luaUnit()
    for _, v in pairs(module_list) do
    	utest:addModuleToTest(v)
    end
    if #module_list == 0 then
        for k,v in pairs(module.get_all()) do
            utest:addModuleToTest(v)
        end
    end
    utest:run()
end

function M.addModuleToTest( modname )
    utest:addModuleToTest(modname)
end

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)

mt.__call = function (...)
	return call(...)
end

-- end ------------------------------------------------------------------------
return M
