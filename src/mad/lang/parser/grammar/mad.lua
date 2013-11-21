local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  grammarMad

SYNOPSIS
  local grammarMad = require"mad.lang.parser.grammarMad"

DESCRIPTION
  Returns the lpeg-compiled grammar of mad

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
local re	 = require('re')
local lpeg = require('lpeg')
local util = require('mad.lang.util')
lpeg.setmaxstack(1024)

-- grammar ---------------------------------------------------------------------

local pattern = require"mad.lang.parser.pattern.luaMadKernel".pattern
..require"mad.lang.parser.pattern.lexer".pattern
..require"mad.lang.parser.pattern.instEvalStmt".pattern

local actions = util.tableMerge(require"mad.lang.parser.actions".actions
, require"mad.lang.parser.actions.instEvalStmt".actions)

M.grammar = function (...)
	local arg = {...}
	for i,v in pairs(arg) do
		actions = util.tableMerge(actions, v)
	end
	return re.compile(pattern, actions)
end

-- end ------------------------------------------------------------------------
return M
