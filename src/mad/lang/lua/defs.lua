local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  luaMadKernel

SYNOPSIS
  local defsLuaMadKernel = require"mad.lang.parser.actions.luaMadKernel".actions

DESCRIPTION
  Returns the actions used by patternLuaMadKernel

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ------------------------------------------------------------------
local tableUtil = require('lua.tableUtil')
local context = require"mad.lang.context.context"

-- utilities ----------------------------------------------------------------

local defs = { }

local function unpackVOE(list)
	if list == nil then return list end
	local endNode,dot,sqrbrc,paran,col = {}, false, false, false, false
	local nodeNo = 0
	local callee
	for i, val in pairs(list) do
		if val == "." then
			dot = true
		elseif dot then
			endNode[nodeNo] = defs.tableAccess(endNode[nodeNo],val,".")
			dot = false
		elseif val == "[" then
			sqrbrc = true
		elseif sqrbrc then
			endNode[nodeNo] = defs.tableAccess(endNode[nodeNo],val,"[")
			sqrbrc = false
		elseif val == ":" then
			col = true
		elseif col then
			callee = val
			col = false
		elseif callee ~= nil then
			local args = val
			endNode[nodeNo] = { type="FunctionCall", callee = defs.tableAccess(endNode[nodeNo],callee, ":"), arguments = args, line = defs._line }
			callee = nil
		elseif not val.type then
			endNode[nodeNo] = { type="FunctionCall", callee = endNode[nodeNo], arguments = val, line = defs._line }
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
	for i, val in ipairs(list) do
		if val == ":" then
			col = true
		elseif col then
			callee = val
			col = false
		elseif callee ~= nil then
			local args = val
			endNode = { type="FunctionCall", callee = defs.tableAccess(endNode,callee, ":"), arguments = args, line = defs._line }
			callee = nil
		else
			endNode = { type="FunctionCall", callee = endNode, arguments = val, line = defs._line }
		end
	end
	return endNode
end

-- defs -----------------------------------------------------------------------

defs._line = 1

function defs.setup(istream, pos)
	local line = 0
	local ofs  = 0
	while ofs < pos do
		local a, b = string.find(istream, "\n", ofs)
		if a then
			ofs = a + 1
			line = line + 1
		else
			break
		end
	end
	defs._line = line
	return true
end

function defs.newLine()
	defs._line = defs._line + 1
end

function defs.error(istream, pos)
	local loc = string.sub(istream, pos, pos)
	if loc == '' then
		error("Unexpected end of input while parsing file ")
	else
		local tok = string.match(istream, '(%w+)', pos) or loc
		local line = 0
		local ofs  = 0
		while ofs < pos do
			local a, b = string.find(istream, "\n", ofs)
			if a then
				ofs = a + 1
				line = line + 1
			else
				break
			end
		end
		error("Unexpected token '"..tok.."' on line "..tostring(line).." in file ")
	end
end

defs.lcomm = function(comm)

end
defs.bcomm = function(comm)

end

defs.tonumber = function(s)
	local n = string.gsub(s, '_', '')
	return tonumber(n)
end
defs.tostring = tostring
function defs.quote(s)
	return string.format("%q", s)
end

local strEscape = {
	["\\r"] = "\r",
	["\\n"] = "\n",
	["\\t"] = "\t",
	["\\\\"] = "\\",
}
function defs.string( op, str, eq )
	return str, (eq or op)
end
function defs.literal(val, op)
	return { type = "Literal", value = val, stringOperator = op, line = defs._line }
end
function defs.boolean(val)
	return val == 'true'
end
function defs.nilExpr()
	return { type = "Literal", value = nil, line = defs._line }
end
function defs.identifier(name)
	return { type = "Variable", name = name, line = defs._line }
end

function defs.chunk(body)
	return { type = "Chunk", body = body, line = defs._line }
end
function defs.stmt(pos, node)
	node.pos = pos
	return node
end

function defs.ifStmt(test, cons, altn)
	if cons.type ~= "Block" then
		cons = defs.blockStmt{ cons }
	end
	if altn and altn.type and altn.type ~= "Block" then
		altn = defs.blockStmt{ altn }
	end
	return { type = "If", test = test, consequent = cons, alternate = altn, line = defs._line }
end
function defs.whileStmt(test, body)
	return { type = "Loop", kind = "While", test = test, body = body, line = defs._line }
end
function defs.repeatStmt(body, test)
	return { type = "Loop", kind = "Repeat", test = test, body = body, line = defs._line }
end
function defs.forStmt(name, init, last, step, body)
	if not body then
		body = step
		step = nil
	end	
	return {
		type = "Loop",
		kind = "For",
		name = name, init = init, last = last, step = step,
		body = body,
		line = defs._line
	}
end
function defs.forInStmt(left, right, body)
	return { type = "GenericFor", names = left, expressions = right, body = body, line = defs._line }
end
function defs.funcDecl(name, args, funcBody)
	local par, body = args, funcBody
	if body.type ~= "Block" then
		body = defs.blockStmt{ body }
	end
	local id,dot,col = {}, false, false
	if type(name) == "table" and #name > 0 then
		for i, val in ipairs(name) do
			if val == "." then
				dot = true
			elseif dot then
				id = defs.tableAccess(id, val, ".")
				dot = false
			elseif val == ":" then
				col = true
			elseif col then
				id = defs.tableAccess(id, val, ".")
				col = false
				table.insert(par,1,defs.identifier("self"))
			else
				id = val
			end
		end
	else
		id = name
	end
	local decl = { type = "FunctionDefinition", id = id, body = body, line = defs._line }
	local params, rest = { }, false
	for i=1, #par do
		local p = par[i]
		if p == "..." then
			rest = true
		else
			params[#params + 1] = p
		end 
	end
	decl.parameters	= params
	decl.rest	  = rest
	return decl
end
function defs.funcExpr(head, body)
	local decl = defs.funcDecl(nil, head, body)
	decl.expression = true
	return decl
end
function defs.blockStmt(body)
	return { type = "Block", body = body }
end
function defs.returnStmt(args)
	return { type = "Return", values = args, line = defs._line }
end
function defs.breakStmt()
	return { type = "Break", line = defs._line }
end
function defs.exprStmt(pos, expr)
	expr.pos = pos
	return expr
end
function defs.unaryExp(o, a)
	return { type = "UnaryExpression", operator = o, argument = a, line = defs._line }
end
function defs.funcCall(varorexp, identthenargs)
	local callee = unpackVOE(varorexp)
	endNode = unpackITA(callee,identthenargs)
	return endNode 
end
function defs.binaryExpr(op, lhs, rhs)
	return { type = "BinaryExpression", operator = op, lhs = lhs, rhs = rhs, line = defs._line }
end
function defs.varlistAssign(lhs, rhs)
	lhs = unpackVOE(lhs)
	if lhs.type then lhs = { lhs } end
	rhs = unpackVOE(rhs)
	if rhs.type then rhs = { rhs } end
	return { type = "Assignment", lhs = lhs, rhs = rhs, line = defs._line }
end
function defs.locFuncDecl(name, head, body)
	local funcDef = defs.funcDecl(name, head, body)
	funcDef.localDeclaration = true
	funcDef.line = defs._line
	return funcDef
end
function defs.locNameList(nlst, explst)
	return { type = "Assignment", lhs = nlst, rhs = explst, localDeclaration = true, line = defs._line }
end
function defs.tableConstr(flst)
	local tbl, i = { type = "Table", explicitExpression = {}, implicitExpression = {}, line = defs._line }, 1
	while i <= #flst do
		if flst[i] == "[" then
			local k = flst[i+1]
			if flst[i+2] and flst[i+2] == "=" and flst[i+3] then
				tbl.explicitExpression[#tbl.explicitExpression+1] = { key = k, value = flst[i+3], computed = true }
				i = i+4
			else
				error("Error with table constructor")
			end
		else
			local val = flst[i]
			if flst[i+1] and flst[i+1] == "=" then
				if flst[i+2] and val and val.type and val.type == "Variable" then
					tbl.explicitExpression[#tbl.explicitExpression+1] = { key = val, value = flst[i+2], computed = false }
					i = i+3
				else
					error("Error with table constructor.")
				end
			else
				tbl.implicitExpression[#tbl.implicitExpression+1] = { value = val }
				i = i+1
			end
		end
	end
	return tbl
end

function defs.prefixExp(varorexp,identthenargs)
	local var = unpackVOE(varorexp)
	var = unpackITA(var,identthenargs)
	return var
end

function defs.tableAccess(lhs, rhs, operator)
	return { type = "BinaryExpression", lhs = lhs, rhs = rhs, operator = operator, line = defs._line }
end

function defs.doStmt(block)
	return { type = "Do", body = block, line = defs._line }
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

	["-_"] = { 9, 'R' },
	["not_"] = { 9, 'R' },
	
	["^"] = { 10, 'R' },
	["#_"] = { 11, 'R' },

}

local shift = table.remove

local function fold_expr(exp, min)
	local lhs = shift(exp, 1)
	if type(lhs) == 'table' and lhs.type == 'UnaryExpression' then
		local op = lhs.operator..'_'
		local info = op_info[op]
		table.insert(exp, 1, lhs.argument)
		lhs.argument = fold_expr(exp, info[1])
	end
	while op_info[exp[1]] ~= nil and op_info[exp[1]][1] >= min do
		local op = shift(exp, 1)
		local info = op_info[op]
		local prec, assoc = info[1], info[2]
		if assoc == 'L' then
			prec = prec + 1
		end
		local rhs = fold_expr(exp, prec)
		lhs = defs.binaryExpr(op, lhs, rhs)
	end
	return lhs
end

function defs.infixExpr(exp)
	return fold_expr(exp, 0)
end

M.defs = defs

-- test suite -----------------------------------------------------------------------
function M.test:setUp()
	self.variable = defs.identifier("dummy")
	self.backUpVariable = defs.identifier("Another")
	self.expression = self.variable
	self.backUpExpression = self.backUpVariable
	self.statement = defs.stmt(1,self.variable)
end

function M.test:tearDown()
	self.variable = nil
	self.backUpVariable = nil
	self.expression = nil
	self.backUpExpression = nil
	self.statement = nil
end

function M.test:error( ut )
	ut:fails(defs.error,[[a = 1]], 0)
end

function M.test:chunk(ut)
	local result = defs.chunk({ self.statement })
	ut:equals(result.type, "Chunk")
	ut:equals(result.body[1], self.statement)
end

function M.test:literal( ut )
	local result = defs.literal(1)
	ut:equals(result.type, "Literal")
end
function M.test:nilExpr( ut )
	local result = defs.nilExpr(1)
	ut:equals(result.type, "Literal")
end
function M.test:identifier( ut )
	local result = defs.identifier(1)
	ut:equals(result.type, "Variable")
end
function M.test:stmt( ut )
	local result = defs.stmt(13, defs.identifier("hello"))
	ut:equals(result.type, "Variable")
	ut:equals(result.pos, 13)
end
function M.test:ifStmt( ut )
	local result = defs.ifStmt(self.expression, self.statement)
	ut:equals(result.type, "If")
	ut:equals(result.test, self.expression)
	ut:differs(result.consequent.type, self.statement.type)
end
function M.test:whileStmt( ut )
	local result = defs.whileStmt(self.expression, defs.blockStmt{self.statement})
	ut:equals(result.type, "Loop")
	ut:equals(result.kind, "While")
	ut:equals(result.test, self.expression)
	ut:equals(result.step, nil)
	ut:equals(result.body.body[1], self.statement)
end
function M.test:repeatStmt( ut )
	local result = defs.repeatStmt(defs.blockStmt{self.statement}, self.expression)
	ut:equals(result.type, "Loop")
	ut:equals(result.kind, "Repeat")
	ut:equals(result.test, self.expression)
	ut:equals(result.step, nil)
	ut:equals(result.body.body[1], self.statement)
end
function M.test:forStmt( ut )
	local result = defs.forStmt("forstmt", self.expression, self.expression, defs.literal(1), defs.blockStmt{self.statement})
	ut:equals(result.type, "Loop")
	ut:equals(result.kind, "For")
	ut:equals(result.last, self.expression)
	ut:equals(result.init, self.expression)
	ut:equals(result.name, "forstmt")
	ut:equals(result.step.value, 1)
	ut:equals(result.body.body[1], self.statement)
end
function M.test:forInStmt( ut )
	local result = defs.forInStmt(self.expression, self.expression, defs.blockStmt{self.statement})
	ut:equals(result.type, "GenericFor")
	ut:equals(result.names, self.expression)
	ut:equals(result.expressions, self.expression)
	ut:equals(result.step, nil)
	ut:equals(result.body.body[1], self.statement)
end
function M.test:funcDecl( ut )
	local result = defs.funcDecl("funcname", {self.variable}, defs.blockStmt{self.statement})
	ut:equals(result.type, "FunctionDefinition")
	ut:equals(result.id, "funcname")
	ut:equals(result.parameters[1], self.variable)
	ut:equals(result.body.body[1], self.statement)
	ut:differs(result.expression, true)
end
function M.test:funcExpr( ut )
	local result = defs.funcExpr({self.variable}, defs.blockStmt{self.statement})
	ut:equals(result.type, "FunctionDefinition")
	ut:equals(result.id, nil)
	ut:equals(result.parameters[1], self.variable)
	ut:equals(result.body.body[1], self.statement)
	ut:equals(result.expression, true)
end
function M.test:blockStmt( ut )
	local result = defs.blockStmt{self.statement}
	ut:equals(result.type, "Block")
	ut:equals(result.body[1], self.statement)
end
function M.test:returnStmt( ut )
	local result = defs.returnStmt{self.expression}
	ut:equals(result.type, "Return")
	ut:equals(result.values[1], self.expression)
end
function M.test:breakStmt( ut )
	local result = defs.breakStmt()
	ut:equals(result.type, "Break")
end
function M.test:exprStmt( ut )
	local result = defs.exprStmt(1, self.expression)
	ut:equals(result.type, self.expression.type)
end
function M.test:unaryExp( ut )
	local result = defs.unaryExp("-", self.variable)
	ut:equals(result.type, "UnaryExpression")
	ut:equals(result.argument.type, self.variable.type)
	ut:equals(result.operator, "-")
end
function M.test:funcCall( ut )
	local result = defs.funcCall({defs.identifier("table")},{":", defs.identifier("func"), {self.expression}})
	ut:equals(result.type, "FunctionCall")
	ut:equals(result.callee.type, "BinaryExpression")
	ut:equals(result.callee.lhs.name, "table")
	ut:equals(result.callee.rhs.name, "func")
	ut:equals(#result.arguments, 1)
	ut:equals(result.arguments[2], self.expression)
	ut:equals(result.callee.operator, "[")
end
function M.test:binaryExpr( ut )
	local result = defs.binaryExpr("+",self.expression,self.backUpExpression)
	ut:equals(result.operator, "+")
	ut:equals(result.lhs, self.expression)
	ut:equals(result.rhs, self.backUpExpression)
end
function M.test:varlistAssign( ut )
	local result = defs.varlistAssign({self.variable, self.backUpVariable},{self.expression, self.backUpExpression})
	ut:equals(#result.lhs,2)
	ut:equals(#result.rhs,2)
	ut:equals(result.rhs[2], self.backUpExpression)
	ut:equals(result.lhs[1], self.variable)
end
function M.test:locFuncDecl( ut )
	local result = defs.locFuncDecl(defs.identifier("name"), {self.expression}, defs.blockStmt{self.statement})
	ut:equals(result.type, "FunctionDefinition")
	ut:equals(result.localDeclaration, true)
end
function M.test:locNameList( ut )
	local test1 = defs.locNameList({self.variable})
	local test2 = defs.locNameList({self.variable, self.backUpVariable}, {self.expression, self.backUpExpression})
	ut:equals(test1.rhs, nil)
	ut:equals(test1.lhs[1], self.variable)
	ut:equals(test1.localDeclaration, true)
	ut:equals(test2.rhs[2], self.backUpExpression)
	ut:equals(test2.lhs[1], self.variable)
	ut:equals(test2.localDeclaration, true)
end
function M.test:tableConstr( ut )
	local result = defs.tableConstr({ self.expression, "[", self.expression, "=", self.backUpExpression, self.variable, "=", self.expression })
	ut:equals(result.explicitExpression[1].computed, true)
	ut:equals(result.explicitExpression[1].key, self.expression)
	ut:equals(result.explicitExpression[1].value, self.backUpExpression)
	ut:equals(result.explicitExpression[2].computed, false)
	ut:equals(result.explicitExpression[2].key, self.variable)
	ut:equals(result.explicitExpression[2].value, self.expression)
	ut:equals(result.implicitExpression[1].value, self.expression)
end
function M.test:prefixExp( ut )
	local result = defs.prefixExp({self.variable, ".", self.backUpVariable}, {})
	ut:equals(result.type, "BinaryExpression")
	ut:equals(result.operator, ".")
	ut:equals(result.lhs, self.variable)
	ut:equals(result.rhs, self.backUpVariable)
end

function M.test:tableAccess( ut )
	local result = defs.tableAccess(self.variable, self.backUpVariable, ".")
	ut:equals(result.type, "BinaryExpression")
	ut:equals(result.operator, ".")
	ut:equals(result.lhs, self.variable)
	ut:equals(result.rhs, self.backUpVariable)
end

function M.test:doStmt( ut )
	local result = defs.doStmt(defs.blockStmt{self.statement})
	ut:equals(result.type, "Do")
	ut:equals(result.body.body[1], self.statement)	
end



-- end ------------------------------------------------------------------------

return M
