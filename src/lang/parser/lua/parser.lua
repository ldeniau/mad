local M = { help = {}, test = {} }

M.help.self = [[
NAME
	lang.parser.lua.parser
DESCRIPTION
	
]]

-- require --------------------------------------------------------------------
local re			=	require"lib.lpeg.re"
local grammar	=	require"lang.parser.lua.grammar".grammar
local actions	=	require"lang.parser.lua.defs".defs
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
	return ast
end


local compiledGrammar = re.compile(grammar, actions)

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.grammar = compiledGrammar
	return self
end


-- end ------------------------------------------------------------------------
return M
