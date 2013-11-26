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
local util = require('lang.util')

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
			local a = table.insert(val,1,defs.identifier("self"))
			endNode[nodeNo] = { type="FunctionCall", callee = defs.tableAccess(endNode[nodeNo],callee, "["), arguments = a, line = defs._line }
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
	for i, val in pairs(list) do
		if val == ":" then
			col = true
		elseif col then
			callee = val
			col = false
		elseif callee ~= nil then
			args = table.insert(val,1,defs.identifier("self"))
			endNode = { type="FunctionCall", callee = defs.tableAccess(endNode,callee, "["), arguments = args, line = defs._line }
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
function defs.string(str)
	return string.gsub(str, "(\\[rnt\\])", strEscape)
end
function defs.literal(val)
	return { type = "Literal", value = val, line = defs._line }
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
	if altn and altn.type then
		altn = { altn }
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
	return { type = "GenericFor", left = left, right = right, body = body, line = defs._line }
end
function defs.funcDecl(name, args, funcBody)
	local par, body = args, funcBody
	if body.type ~= "Block" then
		body = defs.blockStmt{ body }
	end
	local id,dot,col = {}, false, false
	if type(name) == "table" then
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
	decl.params	= params
	decl.rest	  = rest
	return decl
end
function defs.funcExpr(head, body)
	local decl = defs.funcDef(nil, head, body)
	decl.expression = true
	return decl
end
function defs.blockStmt(body)
	return { type = "Block", body = body }
end
function defs.returnStmt(args)
	return { type = "Return", arguments = args, line = defs._line }
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
	return { type = "BinaryExpression", operator = op, left = lhs, right = rhs, line = defs._line }
end
function defs.varlistAssign(lhs, rhs)
	lhs = unpackVOE(lhs)
	if lhs.type then lhs = { lhs } end
	rhs = unpackVOE(rhs)
	if rhs.type then rhs = { rhs } end
	return { type = "Assignment", lhs = lhs, rhs = rhs, line = defs._line }
end
function defs.locFuncDecl(name, head, body)
	return { type = "Assignment", lhs = { name }, rhs = { defs.funcExpr(head, body) }, localDeclaration = true, localFunctionSugar = true, line = defs._line  }
end
function defs.locNameList(nlst, explst)
	return { type = "Assignment", lhs = nlst, rhs = explst, localDeclaration = true, line = defs._line }
end
function defs.tableConstr(flst)
	local tbl, i = { type = "Table", explicitExpr = {}, implicitExpr = {}, line = defs._line }, 1
	while i <= #flst do
		if flst[i] == "[" then
			local k = flst[i+1]
			if flst[i+2] and flst[i+2] == "=" and flst[i+3] then
				tbl.explicitExpr[#tbl.explicitExpr+1] = { key = k, value = flst[i+3], computed = true }
				i = i+4
			else
				error("Error with table constructor")
			end
		else
			local val = flst[i]
			if flst[i+1] and flst[i+1] == "=" then
				if flst[i+2] and val and val.type and val.type == "Variable" then
					tbl.explicitExpr[#tbl.explicitExpr+1] = { key = val, value = flst[i+2], computed = false }
					i = i+3
				else
					error("Error with table constructor.")
				end
			else
				tbl.implicitExpr[#tbl.implicitExpr+1] = { value = val }
				i = i+1
			end
		end
	end
	return tbl
end
function defs.vararg()
	return { type = "Vararg", line = defs._line }
end

function defs.prefixExp(varorexp,identthenargs)
	local var = unpackVOE(varorexp)
	var = unpackITA(var,identthenargs)
	return var
end

function defs.tableAccess(b, e, o)
	return { type = "BinaryExpression", lhs = b, rhs = e, operator = o, line = defs._line }
end
function defs.expression(exp)
	return exp
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
	end
	return lhs
end
end

function defs.infixExpr(exp)
	return fold_expr(exp, 0)
end

M.defs = defs

return M
