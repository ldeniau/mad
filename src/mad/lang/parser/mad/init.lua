local M = { help = {}, test = {}, _author = "Martin Valen", _year = 2013 }

M.help.self = [[
NAME
	mad.lang.parser.mad.init
DESCRIPTION
	
]]

-- require --------------------------------------------------------------------
local parserFactory = require"mad.lang.parser.parserFactory"
local luaParser = require"mad.lang.parser.mad.parser"

-- module --------------------------------------------------------------------
parserFactory.addParser("lua", luaParser())



-- end ------------------------------------------------------------------------
return M
