local M = { help={}, test={}, _author="Richard Hunt and Martin Valen", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
builder.lua

SYNOPSIS
local builder = require "mad.lang.luaAst.builder"

DESCRIPTION
Builds the nodes of the lua AST..

RETURN VALUES
The table of modules and services.

SEE ALSO
None
]]

-- requires ----------------------------------------------------------------

local util	= require('mad.lang.util')
local syntax = require("mad.lang.parser.luaAst.syntax")

-- matches -----------------------------------------------------------------

function M.singleLineComment(comm, loc)
	return syntax.build("SingleLineComment", { comment = comm, loc = loc })
end
function M.multiLineComment(comm, loc)
	return syntax.build("MultiLineComment", { comment = comm, loc = loc })
end

function M.tempnam()
	return M.identifier(util.genid())
end
function M.chunk(body, loc)
	return syntax.build("Chunk", { body = body, loc = loc })
end
function M.identifier(name, loc)
	return syntax.build("Identifier", { name = name, loc = loc })
end
function M.vararg(loc)
	return syntax.build("Vararg", { loc = loc })
end
function M.binaryExpression(op, left, right, loc)
	return syntax.build("BinaryExpression", {
		operator = op, left = left, right = right, loc = loc
	})
end
function M.unaryExpression(op, arg, loc)
	return syntax.build("UnaryExpression", {
		operator = op, argument = arg, loc = loc
	})
end
function M.listExpression(op, exprs, loc)
	return syntax.build("ListExpression", {
		operator = op, expressions = exprs, loc = loc
	})
end

function M.parenExpression(exprs, loc)
	return syntax.build("ParenExpression", {
		expressions = exprs, loc = loc
	})
end
function M.assignmentExpression(left, right, loc)
	return syntax.build("AssignmentExpression", {
		left = left, right = right, loc = loc
	})
end
function M.logicalExpression(op, left, right, loc)
	return syntax.build("LogicalExpression", {
		operator = op, left = left, right = right, loc = loc
	})
end
function M.memberExpression(obj, prop, comp, loc)
	return syntax.build("MemberExpression", {
		object = obj, property = prop, computed = comp or false, loc = loc
	})
end
function M.callExpression(callee, args, loc)
	return syntax.build("CallExpression", {
		callee = callee, arguments = args, loc = loc
	})
end
function M.sendExpression(recv, meth, args, loc)
	return syntax.build("SendExpression", {
		receiver = recv, method = meth, arguments = args, loc = loc
	})
end
function M.literal(val, loc)
	return syntax.build("Literal", { value = val, loc = loc })
end
function M.table(val, loc)
	return syntax.build("Table", { value = val, loc = loc })
end
function M.expressionStatement(expr, loc)
	return syntax.build("ExpressionStatement", { expression = expr, loc = loc })
end
function M.emptyStatement(loc)
	return syntax.build("EmptyStatement", { loc = loc })
end
function M.blockStatement(body, loc)
	return syntax.build("BlockStatement", { body = body, loc = loc })
end
function M.doStatement(body, loc)
	return syntax.build("DoStatement", { body = body, loc = loc })
end
function M.ifStatement(test, cons, alt, loc)
	return syntax.build("IfStatement", {
		test = test, consequent = cons, alternate = alt, loc = loc
	})
end
function M.labelStatement(label, loc)
	return syntax.build("LabelStatement", { label = label, loc = loc })
end
function M.gotoStatement(label, loc)
	return syntax.build("GotoStatement", { label = label, loc = loc })
end
function M.breakStatement(loc)
	return syntax.build("BreakStatement", { loc = loc })
end
function M.returnStatement(arg, loc)
	return syntax.build("ReturnStatement", { arguments = arg, loc = loc })
end
function M.whileStatement(test, body, loc)
	return syntax.build("WhileStatement", {
		test = test, body = body, loc = loc
	})
end
function M.repeatStatement(test, body, loc)
	return syntax.build("RepeatStatement", {
		test = test, body = body, loc = loc
	})
end
function M.forInit(name, value, loc)
	return syntax.build("ForInit", { id = name, value = value, loc = loc })
end
function M.forStatement(init, last, step, body, loc)
	return syntax.build("ForStatement", {
		init = init, last = last, step = step, body = body, loc = loc
	})
end
function M.forNames(names, loc)
	return syntax.build("ForNames", { names = names, loc = loc })
end
function M.forInStatement(init, iter, body, loc)
	return syntax.build("ForInStatement", {
		init = init, iter = iter, body = body, loc = loc
	})
end
function M.localDeclaration(names, exprs, loc)
	return syntax.build("LocalDeclaration", {
		names = names, expressions = exprs, loc = loc
	})
end
function M.functionDeclaration(name, params, body, vararg, rec, loc)
	return syntax.build("FunctionDeclaration", {
		id			= name,
		body		 = body,
		params	  = params or { },
		vararg	  = vararg,
		recursive  = rec,
		loc		  = loc
	})
end
function M.functionExpression(params, body, vararg, loc)
	return syntax.build("FunctionExpression", {
		body		 = body,
		params	  = params or { },
		vararg	  = vararg,
		loc		  = loc
	})
end

return M
