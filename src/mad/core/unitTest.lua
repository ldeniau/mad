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

function M.run( mod, fun )
    if type(mod) == "table" then
        mod = module.get_module_name(mod)
    end
    if fun and type(fun) == "function" then
        fun = module.get_function_name(fun)
    end
    
    if type(mod) ~= "string" then
        error("Module isn't of type string")
    elseif fun and type(fun) ~= "string" then
        error("Function isn't of type string")
    end
    
    utest = luaUnit()
    if fun then
        utest:addFunctionToTest( mod, fun )
    else
        utest:addModuleToTest( mod )
    end
    
    utest:run()
end

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)

mt.__call = function (...)
	return call(...)
end

-- end ------------------------------------------------------------------------
return M
