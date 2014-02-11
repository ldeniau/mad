local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.lang.lua.parser
	
SYNOPSIS
  local parser = mad.lang.getParser("mad")
  local ast    = parser:parse(stringToParse, chunkName, startPosInFile, [startingLine])
  
DESCRIPTION
  Parses a string that contains a chunk of mad code and creates an AST.

  parser:parse(stringToParse, chunkName, startPosInFile, [startingLine])
    -Creates an AST from the given stringToParse, which must be valid mad code.

RETURN VALUES
  None
  
SEE ALSO
  mad.lang - For getting the parser set up correctly.
]]

-- require --------------------------------------------------------------------

local re      = require"lib.lpeg.re"
local grammar = require"mad.lang.mad.grammar".grammar
local defs    = require"mad.lang.mad.defs".defs
local utest   = require"mad.tester"


-- metamethods ----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

local parse = function (self, str, fileName, pos, line)
	defs._line = line or 0
	local ast = self.grammar:match(str, position)
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
    utest.addModuleToTest"mad.lang.mad.grammar"
    utest.addModuleToTest"mad.lang.mad.defs"
end

-- end ------------------------------------------------------------------------
return M
