local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.benchmark
DESCRIPTION
	Runs all benchmarks given to it when called.
]]

-- require --------------------------------------------------------------------

-- module ---------------------------------------------------------------------

local call = function (_, module_list)
    for _, v in pairs(module_list) do
    	require("mad.benchmark."..v)
    end
end



-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)

mt.__call = function (...)
	return call(...)
end

-- end ------------------------------------------------------------------------
return M
