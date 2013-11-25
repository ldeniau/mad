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
local util = require('mad.lang.util')

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
	return { type = "Literal", value = val }
end
function defs.boolean(val)
	return val == 'true'
end
function defs.nilExpr()
	return { type = "Literal", value = nil }
end
function defs.identifier(name)
	return { type = "Variable", name = name }
end

function defs.chunk(body)
	return { type = "Chunk", body = body }
end
function defs.stmt(pos, node)
	node.pos = pos
	return node
end

function defs.ifStmt(test, cons, altn)
	if cons.type then
		cons = { cons }
	end
	if altn and altn.type then
		altn = { altn }
	end
	return { type = "If", test = test, consequent = cons, alternate = altn }
end
function defs.whileStmt(test, body)
	return { type = "Loop", kind = "While", test = test, body = body }
end
function defs.repeatStmt(body, test)
	return { type = "Loop", kind = "Repeat", test = test, body = body }
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
		body = body
	}
end
function defs.forInStmt(left, right, body)
	return { type = "GenericFor", left = left, right = right, body = body }
end
function defs.funcDecl(name, args, funcBody)
	local par, body = args, funcBody
	if body.type then
		body = { body }
	end
	local id,dot,col = {}, false, false
	if type(name) == "table" then
		for i, val in ipairs(name) do
			if val == "." then
				dot = true
			elseif dot then
				id = defs.TableAccess(id,val,false)
				dot = false
			elseif val == ":" then
				col = true
			elseif col then
				id = defs.TableAccess(id,val)
				col = false
				table.insert(par,1,defs.identifier("self"))
			else
				id = val
			end
		end
	else
		id = name
	end
	local decl = { type = "FunctionDefinition", id = id, body = body }
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
	return body
end
function defs.returnStmt(args)
	return { type = "Return", arguments = args }
end
function defs.breakStmt()
	return { type = "Break" }
end
function defs.exprStmt(pos, expr)
	expr.pos = pos
	return expr
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
	if lhs.type then lhs = { lhs } end
	rhs = unpackVOE(rhs)
	if rhs.type then rhs = { rhs } end
	return { type = "Assignment", lhs = lhs, rhs = rhs }
end
function defs.locFuncDecl(name, head, body)
	return { type = "Assignment", lhs = { name }, rhs = { defs.funcExpr(head, body) }, localDeclaration = true  }
end
function defs.locNameList(nlst, explst)
	return { type = "Assignment", lhs = nlst, rhs = explst, localDeclaration = true }
end
function defs.tableConstr(flst)
	local tbl, i = { type = "Table", explicitExpr = {}, implicitExpr = {} }, 1
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
	return { type = "Vararg" }
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
	return exp
end

function defs.doStmt(block)
	return { type = "Do", body = block }
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

M.actions = defs

return M
