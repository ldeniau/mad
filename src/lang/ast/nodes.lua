local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  nodes

SYNOPSIS
  local nodes = require"lang.ast.nodes"

DESCRIPTION

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local util = require('mad.lang.util')

-- module ---------------------------------------------------------------------

local nodes = [[
Chunk:
	body = list of Statement
Assignment:
	lhs = list of Variable or Table Access
	rhs = list of Expression
Function Call:
	name = Variable or Table Access
	arguments = list of Expression
Label:
	name = String
Break:
Goto:
	name = Label
Do:
	body = list of Statement
Loop:
	body = list of Statement
	kind = while/for/repeat
GenericFor:
	body = list of Statement
	names = list of Variable
	expressions = list of Expression
FunctionDefinition:
	body = list of Statement
	parameters = (list of Variable)
	rest = Boolean
Return:
	values = list of Expression
Vararg:
TableAccess:
	parent = Variable
	child = Variable
	computed = Boolean
BinaryExpression:
	lhs = Expression
	operator = "+", "-", "*", "/", "^", "%", "..", "==", "~=", ">=", ">", "<=", "<",
	rhs = Expression
UnaryExpression:
	operator = "not", "-", "#"
	argument = Expression
Variable:
	name = String
Literal:
	value = nil, true, false, number, string
Table:
	implicitExpr = list of Expression
	explicitExpr = list of table of:
		{
			key = String,
			value = Expression,
			computed = Boolean
		}
If:
	test = Expression
	consequent = list of Statement
	alternate = list of Statement
]]


-- end ------------------------------------------------------------------------
return M
