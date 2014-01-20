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

-- defs -----------------------------------------------------------------------

local defs = { }

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
		error("Unexpected token '"..tok.."' on line "..tostring(line).." in file")
	end
end

-- block and chunk

function defs.chunk( _, block )
    return { ast_id = "chunk", block }
end

function defs.block( _, ... )
    return { ast_id = "block", ... }
end

-- stmt

function defs.breakstmt()
    return { ast_id = "break" }
end

function defs.gotostmt( label )
    return { ast_id = "goto", label }
end

function defs.dostmt( block )
    return { ast_id = "do", block }
end

function defs.assign( lhs, rhs )
    return { ast_id = "assign", lhs = lhs, rhs = rhs }
end

function defs.locassign( lhs, rhs )
    return { ast_id = "assign", localdef = true, lhs = lhs, rhs = rhs }
end

function defs.whilestmt( exp, block)
    return { ast_id = "while", test = exp, block }
end

function defs.repeatstmt( block, exp )
    return { ast_id = "repeat", test = exp, block }
end

function defs.ifstmt( test, block, elseifTbl, elseBlock)
    return { ast_id = "if", test = test, block, elseifTable = elseifTbl, elseBlock = elseBlock }
end

function defs.forstmt( name, first, last, step, block)
    if not block then block = step step = nil end
    return { ast_id = "for", name = name, first = first, last = last, step = step, block }
end

function defs.forinstmt( names, exps, block )
    return { ast_id = "forin", names = names, expressions = exps, block }
end

-- extra stmts

function defs.retstmt ( _, ... )
    return { ast_id = "return", ... }
end

function defs.label ( _, val )
    return { ast_id = "label", val }
end

-- expressions

function defs.exp ( _, exp )
    exp.line = defs._line
    return exp
end

function defs.orexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.andexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.logexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.catexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.sumexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.prodexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.unexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end

function defs.powexp( _, first, ... )
    if ... == nil then return first end
    return {ast_id = "expr", first, ...}
end


local function createTreeFromListOfTableIndexAndCalls ( startnode, ... )
    local skip, ret, args = false, startnode, {...}
    for i = 1, #args, 2 do
        if not skip then
            if args[i] == ":" then
                ret = { ast_id = "call", callee = ret, selfExp = args[i+1], arguments = args[i+3] }
                skip = true
            elseif args[i] == "." then
                ret = { ast_id = "tblaccess", lhs = ret, rhs = args[i+1], literalidx = true }
            elseif args[i] == "(" then
                ret = { ast_id = "call", callee = ret, arguments = args[i+1] }
            elseif args[i] == "[" then
                ret = { ast_id = "tblaccess", lhs = ret, rhs = args[i+1] }
            end
        else
            skip = false
        end
    end
    return ret
end

function defs.varexp ( name, ... )
    return createTreeFromListOfTableIndexAndCalls( name, ... )
end

function defs.grpexp ( exp )
    return { ast_id = "groupexp", exp }
end


-- variable definitions

function defs.vardef ( name, ... )
    return createTreeFromListOfTableIndexAndCalls( name, ... )
end

-- function definition

function defs.fundef_a ( params, body )
    return { ast_id = "fundef", parameters = params, body }
end

function defs.fundef_n ( name, params, body )
    return { ast_id = "fundef", name = name, parameters = params, body }
end

function defs.fundef_l ( name, params, body )
    return { ast_id = "fundef", localdef = true, name = name, parameters = params, body }
end

function defs.funname ( names, selfname )
    local ret = names[1]
    for i = 2, #names do
        ret = { ast_id = "binexp", lhs = ret, rhs = names[i], operator = "." }
    end
    if selfname then
        ret = { ast_id = "binexp", lhs = ret, rhs = selfname, operator = ":" }
    end
    return ret
end

function defs.funparm ( names, ellipsis )
    names = names or {}
    table.insert(names, ellipsis)
    return names
end

function defs.funbody ( params, body )
    if not body then
        body = params
        params = nil
    end
    return params, body
end

function defs.funstmt ( name, ... )
    return createTreeFromListOfTableIndexAndCalls( name, ... )
end

function defs.funcall ( op, name, ... )
    if op == ":" then
        return op, name, "(", {...}
    elseif type(op) == "table" then
        return "(", { op, name, ... }
    else
        return "(", {}
    end    
end

-- table

function defs.tabledef( _, ... )
	return { ast_id = "tableDef", ... }
end

function defs.field( _, op, key, val )
    if not key then
        val = op
        op = nil
    end
    if not val then 
        val = key
        key = op
        op = nil
    end
    return { ast_id = "field", key = key, value = val, operator = op }
end

function defs.tableidx( op, exp )
    return op, exp
end

-- basic lexem

function defs.literal(...)
	return { ast_id = "literal", ..., line = defs._line }
end

function defs.name(...)
	return { ast_id = "name", ..., line = defs._line }
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
	ut:equals(result.arguments[1], self.expression)
	ut:equals(result.callee.operator, ":")
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
