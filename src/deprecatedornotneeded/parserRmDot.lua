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
local utest   = require"mad.core.unitTest"


-- metamethods ----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

local grammar = [=[
    chunk       <- {|block|} -> chunk
    block       <- (word / {.})*
    word        <- special / name
    special     <- {real / const / "mech_sep" / "assembly_id" / "slot_id"}
    real        <- [rR][eE][aA][lL]
    const       <- [cC][oO][nN][sS][tT]
    name        <- {~ident~}->addUnderscore 
    ident       <- [A-Za-z_][A-Za-z0-9_.$]*
]=]

local parse = function (self, str, fileName, pos, line)
	local ast = self.grammar:match(str, position)
	return ast
end

call = function (_, ...)
	local self = {}
	self.parse = parse
	self.grammar = re.compile(grammar, {
	    chunk = function(str)
	        local ret = table.concat(str)
	        return ret
	    end,
	    addUnderscore = function(name)
	        name = string.gsub(name, '(_)', '__')
	        name = string.gsub(name, '(%.)', '_')
	        return name
	    end
	    })
	return self
end

-- end ------------------------------------------------------------------------
return M
