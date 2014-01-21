local M = { help = {}, test = {} }

M.help.self = [[
NAME
	lang.parser.lua.parser

DESCRIPTION	
]]

-- require --------------------------------------------------------------------

local re      = require"lib.lpeg.re"
local grammar = require"mad.lang.lua.grammar-actions".grammar
local actions = require"mad.lang.lua.defs".defs


-- metamethods ----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

local parse = function (self, inputStream, fileName, pos)
	local position = pos or 1
	local startTime = os.clock()
	local ast = self.grammar:match(inputStream, position)
	local totalTime = os.clock() - startTime
    print(string.format("elapsed time: %.2fs", totalTime))
	return ast
end

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.grammar = re.compile(grammar, actions)
	return self
end

-- test -----------------------------------------------------------------------
function M.test:setUp()
	self.parser = M()
end

function M.test:tearDown()
	self.parser = nil
end

function M.test:parse(ut)
	local ast = self.parser:parse([[a = 1]])
	ut:equals(ast.type, "Chunk")
	ut:equals(#ast.body, 1)
	ut:equals(ast.body[1].type, "Assignment")
end

-- end ------------------------------------------------------------------------
return M
