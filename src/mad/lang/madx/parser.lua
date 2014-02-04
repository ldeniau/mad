local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.lang.sequence.parser
	
SYNOPSIS
  local parser = mad.lang.getParser("sequence")
  local ast    = parser:parse(stringToParse, chunkName, startPosInFile, [startingLine])
  
DESCRIPTION
  Parses a string that contains a chunk of Lua code and creates an AST.

  parser:parse(stringToParse, chunkName, startPosInFile, [startingLine])
    -Creates an AST from the given stringToParse, which must be valid MAD-X code.

RETURN VALUES
  None
  
SEE ALSO
  mad.lang - For getting the parser set up correctly.
]]

-- require --------------------------------------------------------------------

local re      = require"lib.lpeg.re"
local grammar = require"mad.lang.madx.grammar".grammar
local rmDot   = require"mad.lang.madx.parserRmDot"
local defs    = require"mad.lang.madx.defs".defs
local utest   = require"mad.core.unitTest"


-- metamethods ----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

local parse = function (self, str, fileName, pos, line)
    local str = self.rmDot:parse(str)
	defs._line = line
	local ast = self.grammar:match(str, position)
	return ast
end

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.rmDot = rmDot()
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
    utest.addModuleToTest("mad.lang.madx.grammar")
end

-- end ------------------------------------------------------------------------
return M
