local M = { help = {}, test = {} }

M.help.self = [[
NAME
	lang.parser.lua.init
DESCRIPTION
	
]]

-- require --------------------------------------------------------------------
local parserFactory = require"lang.parser.parserFactory"
local parser = require"lang.parser.lua.parser"

-- module --------------------------------------------------------------------
parserFactory.registerParser("lua", parser)



-- end ------------------------------------------------------------------------
return M
