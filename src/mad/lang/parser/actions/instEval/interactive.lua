local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  instEval.interactive

SYNOPSIS
  local defsInstEvalInclude = require"mad.lang.parser.actions.instEval.include".actions
  But this should be done in instEvalStmt.lua

DESCRIPTION
  Implements C/C++-style include.

RETURN VALUES
  

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local env = require"mad.lang.environment"

-- module ---------------------------------------------------------------------
local defs = {}
defs.instEval = {}

defs.instEval.interactive = function (istream, pos)
	local ret
	
	return pos, ret
end

M.actions = defs

-- end ------------------------------------------------------------------------
return M
