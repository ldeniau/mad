local M = { help = {}, test = {} }

M.help.self = [[
NAME
	lang.parser.lua.parser

DESCRIPTION	
]]

-- require --------------------------------------------------------------------

local re      = require"lib.lpeg.re"
local grammar = require"mad.lang.lua.grammar".grammar
local defs    = require"mad.lang.lua.defs".defs
local utest   = require"mad.core.unitTest"


-- metamethods ----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

--[[local function countNodes(table)
    local ret = 0
    for k,v in pairs(table) do
        if type(v) == "table" then
            ret = ret+1+countNodes(v)
        end
    end
    return ret
end]]

local parse = function (self, str, fileName, pos, line)
	defs._line = line
	local startTime = os.clock()
	local ast = self.grammar:match(str, position)
	local totalTime = os.clock() - startTime
    --print(string.format("elapsed time: %.2fs", totalTime))
    --print("number of nodes:             "..tostring(countNodes(ast)))
	return ast
end

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.grammar = re.compile(grammar, defs)
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
	ut:equals(ast.ast_id, "chunk")
	ut:equals(#ast.block, 1)
	ut:equals(ast.block[1].ast_id, "assign")
end

function M.test:self(ut)
    utest.addModuleToTest("mad.lang.lua.grammar")
end

-- end ------------------------------------------------------------------------
return M
