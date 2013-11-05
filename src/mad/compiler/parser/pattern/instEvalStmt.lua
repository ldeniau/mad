local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  instEvalStmt (Instant Evaluation Statement)

SYNOPSIS
  local instEvalStmt = require"mad.compiler.parser.pattern.instEvalStmt"

DESCRIPTION
  Returns a grammar 

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------

M.pattern = [[
	
	instant_eval_stmt <- (
		"@" <ident>
	) => instantEvalStmt

]]

return M
