local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  luaMadKernel

SYNOPSIS
  local defsLuaMadKernel = require"mad.compiler.parser.defs.luaMadKernel".defs

DESCRIPTION
  Returns the actions used by patternLuaMadKernel

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ------------------------------------------------------------------
local util = require('mad.compiler.util')

-- utilities ----------------------------------------------------------------

local function unpackVOE(list)
	if list == nil then return list end
	local endNode,dot,sqrbrc,paran,col = {}, false, false, false, false
	local nodeNo = 0
	local callee
	for i, val in pairs(list) do
		if val == "." then
			dot = true
		elseif dot then
			endNode[nodeNo] = defs.memberExpr(endNode[nodeNo],val,false)
			dot = false
		elseif val == "[" then
			sqrbrc = true
		elseif sqrbrc then
			endNode[nodeNo] = defs.memberExpr(endNode[nodeNo],val,true)
			sqrbrc = false
		elseif val == ":" then
			col = true
		elseif col then
			callee = val
			col = false
		elseif callee ~= nil then
			local a = table.insert(val,1,defs.identifier("self"))
			endNode[nodeNo] = { type="CallExpression", callee = defs.memberExpr(endNode[nodeNo],callee), arguments = a}
			callee = nil
		elseif not val.type then
			endNode[nodeNo] = { type="CallExpression", callee = endNode[nodeNo], arguments = val }
		else
			nodeNo = nodeNo + 1
			endNode[nodeNo] = val
		end
	end
	if #endNode == 1 then endNode = endNode[1] end
	return endNode
end
local function unpackITA(callee,list)
	local endNode,col,callee = callee, false,nil
	for i, val in pairs(list) do
		if val == ":" then
			col = true
		elseif col then
			callee = val
			col = false
		elseif callee ~= nil then
			args = table.insert(val,1,defs.identifier("self"))
			endNode = { type="CallExpression", callee = defs.memberExpr(endNode,callee), arguments = args}
			callee = nil
		else
			endNode = { type="CallExpression", callee = endNode, arguments = val }
		end
	end
	return endNode
end

-- defs -----------------------------------------------------------------------

local defs = { }

function defs.chunk(body)
	return { type = "Chunk", body = body }
end
function defs.stmt(pos, node)
	node.pos = pos
	return node
end

function defs.ifStmt(test, cons, altn)
	if cons.type ~= "BlockStatement" then
		cons = defs.blockStmt{ cons }
	end
	if altn and altn.type ~= "BlockStatement" then
		altn = defs.blockStmt{ altn }
	end
	return { type = "IfStatement", test = test, consequent = cons, alternate = altn }
end
function defs.whileStmt(test, body)
	return { type = "WhileStatement", test = test, body = body }
end
function defs.repeatStmt(body, test)
	return { type = "RepeatStatement", test = test, body = body }
end
function defs.forStmt(name, init, last, step, body)
	if not body then
		body = step
		step = nil
	end	
	return {
		type = "ForStatement",
		name = name, init = init, last = last, step = step,
		body = body
	}
end
function defs.forInStmt(left, right, body)
	return { type = "ForInStatement", left = left, right = right, body = body }
end
function defs.funcDecl(name, args, funcBody)
	local par, body = args, funcBody
	if body.type ~= "BlockStatement" then
		body = defs.blockStmt{ defs.returnStmt{ body } }
	end
	local id,dot,col = {}, false, false
	if type(name) == "table" then
		for i, val in ipairs(name) do
			if val == "." then
				dot = true
			elseif dot then
				id = defs.memberExpr(id,val,false)
				dot = false
			elseif val == ":" then
				col = true
			elseif col then
				id = defs.memberExpr(id,val)
				col = false
				table.insert(par,1,defs.identifier("self"))
			else
				id = val
			end
		end
	else
		id = name
	end
	local decl = { type = "FunctionDeclaration", id = id, body = body }
	local params, rest = { }, false
	for i=1, #par do
		local p = par[i]
		if p == "..." then
			rest = true
		else
			params[#params + 1] = p
		end 
	end
	decl.params	= params
	decl.rest	  = rest
	return decl
end
function defs.funcExpr(head, body)
	local decl = defs.funcDecl(nil, head, body)
	decl.expression = true
	return decl
end
function defs.lambdaDecl(head, expr)
	local body = defs.blockStmt({defs.returnStmt(expr)})
	local decl = defs.funcExpr(head,body)
	decl.lambda = true
	if #head == 0 then decl.lambdaNoArgs = true end
	return decl
end
function defs.blockStmt(body)
	return {
		type = "BlockStatement",
		body = body
	}
end
function defs.returnStmt(args)
	return { type = "ReturnStatement", arguments = args }
end
function defs.breakStmt()
	return { type = "BreakStatement" }
end
function defs.exprStmt(pos, expr)
	return { type = "ExpressionStatement", expression = expr, pos = pos }
end
function defs.unaryExp(o, a)
	return { type = "UnaryExpression", operator = o, argument = a }
end
function defs.funcCall(varorexp, identthenargs)
	local callee = unpackVOE(varorexp)
	endNode = unpackITA(callee,identthenargs)
	return endNode 
end
function defs.binaryExpr(op, lhs, rhs)
	return { type = "BinaryExpression", operator = op, left = lhs, right = rhs }
end
function defs.varlistAssign(lhs, rhs)
	lhs = unpackVOE(lhs)
	if lhs.type then lhs = {lhs} end
	rhs = unpackVOE(rhs)
	if rhs.type then rhs = {rhs} end
	return { type = "AssignmentExpression", left = lhs, right = rhs }
end
function defs.opAssign(lhs,op,rhs)
	local decl = {}
	decl.type = "OperatorAssignmentExpression"
	decl.left = lhs	
	decl.operator = op
	decl.right = rhs
	return decl
end
function defs.locFuncDecl(name, head, body)
	return { type = "LocalDeclaration", names = {name}, expressions = {defs.funcExpr(head, body)} }
end
function defs.locNameList(nlst, explst)
	return { type = "LocalDeclaration", names = nlst, expressions = explst }
end
function defs.tableConstr(flst)
	local tbl, no, i = { type = "TableExpression", members = {} }, 1, 1
	while i <= #flst do
		if flst[i] == "[" then
			local k = flst[i+1]
			if flst[i+2] and flst[i+2] == "=" and flst[i+3] then
				tbl.members[#tbl.members+1] = { key = k, value = flst[i+3] }
				i = i+4
			else
				error("Error with table constructor")
			end
		else
			local val = flst[i]
			if flst[i+1] and flst[i+1] == "=" then
				if flst[i+2] and val and val.type and val.type == "Identifier" then
					tbl.members[#tbl.members+1] = { key = defs.literal(val.name), value = flst[i+2] }
					i = i+3
				else
					error("Error with table constructor.")
				end
			else
				tbl.members[#tbl.members+1] = { number = defs.literal(no), value = val }
				no = no+1
				i = i+1
			end
		end
	end
	return tbl
end
function defs.variable(val)
	return { type = "Vararg", value = val }
end

function defs.prefixExp(varorexp,identthenargs)
	local var = unpackVOE(varorexp)
	var = unpackITA(var,identthenargs)
	return var
end

function defs.memberExpr(b, e, c)
	return { type = "MemberExpression", object = b, property = e, computed = c }
end
function defs.expression(exp)
	return { type = "Expression", expression = exp }
end

function defs.doStmt(block)
	return { type = "DoStatement", body = block }
end

function defs.logicalExpr(op, lhs, rhs)
   return { type = "LogicalExpression", operator = op, left = lhs, right = rhs }
end

local op_info = {
	["or"] = { 1, 'L' },
	["and"] = { 2, 'L' },

	["=="] = { 3, 'L' },
	["~="] = { 3, 'L' },

	["in"] = { 4, 'L' },

	[">="] = { 5, 'L' },
	["<="] = { 5, 'L' },
	[">"] = { 5, 'L' },
	["<"] = { 5, 'L' },

	[".."] = { 6, 'L' },

	["-"] = { 7, 'L' },
	["+"] = { 7, 'L' },

	["*"] = { 8, 'L' },
	["/"] = { 8, 'L' },
	["%"] = { 8, 'L' },

	["^"] = { 9, 'R' },

}

local shift = table.remove

local function fold_infix(exp, lhs, min)
	while op_info[exp[1]] ~= nil and op_info[exp[1]][1] >= min do
		local op  = shift(exp, 1)
		local rhs = shift(exp, 1)
		while op_info[exp[1]] ~= nil do
			local info = op_info[exp[1]]
			local prec, assoc = info[1], info[2]
			if prec > op_info[op][1] or (assoc == 'R' and prec == op_info[op][1]) then
				rhs = fold_infix(exp, rhs, prec)
			else
				break
			end
		end
		if op == "or" or op == "and" then
			lhs = defs.logicalExpr(op, lhs, rhs)
		else
			lhs = defs.binaryExpr(op, lhs, rhs)
		end
	end
	return lhs
end

function defs.infixExpr(exp)
	return fold_infix(exp, shift(exp, 1), 0)
end

defs._setCurrentFileName = setCurrentFileName
defs._getCurrentFileName = getCurrentFileName

M.defs = defs

return M
