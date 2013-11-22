local M = { help = {}, test = {}, _author = "Martin Valen", _year = 2013 }

M.help.self = [[
NAME
	mad.lang.parser.mad.parser
DESCRIPTION
	
]]

-- require --------------------------------------------------------------------
local re = require"lib.lpeg.re"
local luaGrammar = require"mad.lang.parser.mad.grammar.luaGrammar".pattern
local actions = require"mad.lang.parser.mad.grammar.actions".actions

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

local parse = function (self, inputStream, fileName, pos)
	local position = pos or 1
	local ast = self.grammar:match(inputStream, position)
	ast.file = { name = fileName, inputStream = inputStream }
	return ast
end


local grammar = re.compile(luaGrammar, actions)

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.grammar = grammar
	return self
end


-- end ------------------------------------------------------------------------
return M
