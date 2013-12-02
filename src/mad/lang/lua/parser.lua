local M = { help = {}, test = {} }

M.help.self = [[
NAME
	lang.parser.lua.parser
DESCRIPTION
	
]]

-- require --------------------------------------------------------------------
local re			=	require"libs.lpeg.re"
local grammar	=	require"mad.lang.lua.grammar".grammar
local actions	=	require"mad.lang.lua.defs".defs
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

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.grammar = re.compile(grammar, actions)
	return self
end


-- end ------------------------------------------------------------------------
return M
