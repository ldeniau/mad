local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  grammarMad

SYNOPSIS
  local grammarMad = require"mad.compiler.parser.grammarMad"

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
local util = require('mad.compiler.util')
lpeg.setmaxstack(1024)

-- grammar ---------------------------------------------------------------------

local pattern = require"mad.compiler.parser.pattern.luaMadKernel".pattern
..require"mad.compiler.parser.pattern.lexer".pattern
..require"mad.compiler.parser.pattern.instEvalStmt".pattern


local defs = util.tableMerge(require"mad.compiler.parser.defs.luaMadKernel".defs
, require"mad.compiler.parser.defs.lexer".defs
, require"mad.compiler.parser.defs.instEvalStmt".defs
,	require"mad.compiler.parser.defs.error".defs)

M.grammar = re.compile(pattern,defs)

return M
