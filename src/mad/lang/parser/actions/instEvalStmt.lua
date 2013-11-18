local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  instEvalStmt (Instant Evaluation Statement)

SYNOPSIS
  local defsInstEvalStmt = require"mad.lang.parser.actions.instEvalStmt".actions

DESCRIPTION
  Returns the actions used by patternInstEvalStmt

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local util = require"mad.lang.util"

-- module ---------------------------------------------------------------------

M.actions = {}

M.actions.instEval = M.actions.instEval or {}

function M.actions.instantEvalStmt(istream, pos, name)
	return M.actions.instEval[name.name](string.sub(istream,pos),pos)
end

-- fill instEval ----------
M.defs = util.tableMerge(M.actions, require"mad.lang.parser.actions.instEval.include".actions)



-- end ------------------------------------------------------------------------
return M
