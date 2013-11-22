local M = { help = {}, test = {}, _author = "Martin Valen", _year = 2013 }

M.help.self = [[
NAME
	mad.application.handleArguments

]]

-- require --------------------------------------------------------------------
local fileHandler = require"mad.application.util.fileHandler"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

-- This will need to be changed, only returns first argument atm.
call = function (modSelf, arg)
	return arg[1]
end



-- end ------------------------------------------------------------------------
return M
