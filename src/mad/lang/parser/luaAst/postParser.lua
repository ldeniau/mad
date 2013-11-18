local B = require('mad.lang.parser.luaAst.builder')
local util = require('mad.lang.util')
local Context = require"mad.lang.parser.luaAst.context"

local notLambda = 0
local isLambda = 1

local match = { }

local function makeLambda( func, lambdaNoArgs )
	local requireMad = B.callExpression( B.identifier("require"), { B.literal("mad") } )
	local lambda = B.memberExpression( requireMad, B.identifier("lambda") )
	local lambdaNew = B.memberExpression( lambda, B.identifier("new") )
	return B.callExpression( lambdaNew, { func, B.literal( lambdaNoArgs ) } )
end
local function makeEval( identifier )
	local requireMad = B.callExpression( B.identifier("require"), { B.literal("mad") } )
	local lambda = B.memberExpression( requireMad, B.identifier("lambda") )
	local lambdaEval = B.memberExpression( lambda, B.identifier("__eval") )
	return B.callExpression( lambdaEval, { identifier } )
end
local function initializeLambda()
	local requireMad = B.callExpression( B.identifier("require"), { B.literal("mad") } )
	local lambda = B.memberExpression( requireMad, B.identifier("lambda") )
	local lambdaNew = B.memberExpression( lambda, B.identifier("new") )
	return B.localDeclaration( {B.identifier("__newLambda")}, {lambdaNew} )
end
local function initializeEval()
	local requireMad = B.callExpression( B.identifier("require"), { B.literal("mad") } )
	local lambda = B.memberExpression( requireMad, B.identifier("lambda") )
	local lambdaEval = B.memberExpression( lambda, B.identifier("__eval") )
	return B.localDeclaration( {B.identifier("__eval")}, {lambdaEval} )
end

function match:SingleLineComment(node)
	return B.singleLineComment(node.comment)
end
function match:MultiLineComment(node)
	return B.multiLineComment(node.comment)
end

function match:Chunk(node)
	self.hoist = { }
	self.block = { }
	--self.block[#self.block + 1] = initializeLambda()
	--self.block[#self.block + 1] = initializeEval()
	for i=1, #node.body do
		local stmt = self:get(node.body[i])
		self.block[#self.block + 1] = stmt
	end
	for i=#self.hoist, 1, -1 do
		table.insert(self.block, 1, self.hoist[i])
	end
	return B.chunk(self.block)
end
function match:Literal(node)
	return B.literal(node.value)
end
function match:Identifier(node)
	return B.identifier(node.name)
end
function match:AssignmentExpression(node)
	local body = { }
	local decl = { }
	for i=1, #node.left do
		local n = node.left[i]
		if n.type == 'Identifier' and not self.ctx:lookup(n.name) then
			if node.right[i] and node.right[i].type == "FunctionDefinition" and node.right[i].lambda then
				self.ctx:globalDefine(n.name, isLambda)
			else
				self.ctx:globalDefine(n.name, notLambda)
			end
		end
	end
	return B.assignmentExpression(
		self:list(node.left), self:list(node.right, "lookup")
	)
end
function match:OperatorAssignmentExpression(node)
	local n = node.left
	if n.type == 'Identifier' and not self.ctx:lookup(n.name) then
		self.ctx:globalDefine(n.name)
	end
	local op = node.operator
	if op == "+=" then op = "+"
	elseif op == "-=" then op = "-"
	elseif op == "/=" then op = "/"
	elseif op == "*=" then op = "*"
	else error("Operator "..op.." not defined.") end
	local left,right = self:get(node.left),self:get(node.right, "lookup")
	local binexp = B.binaryExpression(op,left,right)
	return B.assignmentExpression({left},{binexp})
end
function match:LocalDeclaration(node)
	local body, decl, expr = nil,{},{}
	for i=1, #node.names do
		local n = node.names[i]
		if node.expressions and node.expressions[i] then
			if node.expressions[i].type == "FunctionDeclaration" and node.expressions[i].lambda then
				self.ctx:define(n.name, isLambda)
			else
				self.ctx:define(n.name, notLambda)
			end
		else
			self.ctx:define(n.name)
		end
		decl[#decl + 1] = self:get(n)
	end
	if node.expressions then
		for i=1, #node.expressions do
			local e = node.expressions[i]
			expr[#expr+1] = e
		end
		body = B.localDeclaration(self:list(node.names), self:list(node.expressions, "lookup"))
	else
		body = B.localDeclaration(self:list(node.names), { })
	end
	return body
end
function match:DoStatement(node)
	return B.doStatement(self:get(node.body))
end
function match:MemberExpression(node)
	return B.memberExpression(
		self:get(node.object, "lookup"), self:get(node.property), node.computed
	)
end
function match:SelfExpression(node)
	return B.identifier('self')
end

function match:ReturnStatement(node)
	if self.retsig then
		return B.doStatement(
			B.blockStatement{
				B.assignmentExpression(
					{ self.retsig }, { B.literal(true) }
				);
				B.assignmentExpression(
					{ self.retval }, self:list(node.arguments, "lookup")
				);
				B.returnStatement{ self.retval }
			}
		)
	end
	return B.returnStatement(self:list(node.arguments, "lookup"))
end

function match:IfStatement(node)
	local test, cons, altn = self:get(node.test, "lookup")
	if node.consequent then
		cons = self:get(node.consequent, "lookup")
	end
	if node.alternate then
		altn = self:get(node.alternate, "lookup")
	end
	local stmt = B.ifStatement(test, cons, altn)
	return stmt
end
function match:BreakStatement(node)
	return B.breakStatement()
end
function match:ContinueStatement(node)
	return B.gotoStatement(self.loop)
end

function match:LogicalExpression(node)
	return B.logicalExpression(
		node.operator, self:get(node.left, "lookup"), self:get(node.right, "lookup")
	)
end
function match:BinaryExpression(node)
	local o = node.operator
	return B.binaryExpression(o, self:get(node.left, "lookup"), self:get(node.right, "lookup"))
end
function match:UnaryExpression(node)
	local o = node.operator
	local a = self:get(node.argument, "lookup")
	return B.unaryExpression(o, a)
end

function match:FunctionDeclaration(node)
	local name
	if not node.expression then
		name = self:get(node.id)
	end

	local params  = { }
	local prelude = { }
	local vararg  = false

	self.ctx:enter()

	for i=1, #node.params do
		local name = self:get(node.params[i])
		self.ctx:define(name.name)
		params[#params + 1] = name
	end

	if node.rest then
		params[#params + 1] = B.vararg()
	end

	local body = self:get(node.body)
	for i=#prelude, 1, -1 do
		table.insert(body.body, 1, prelude[i])
	end

	local func = B.functionExpression(params, body, vararg)

	self.ctx:leave()

	if node.expression then
		if node.lambda then
			return makeLambda( func, node.lambda == 0 )
		else
			return func
		end
	end

	local decl = {}

	if name.type == 'Identifier' and not self.ctx:lookup(name.name) then
		self.ctx:globalDefine(name.name, notLambda)
		decl[#decl + 1] = self:get(name)
	end 

	local frag = {}
	
	if #decl > 0 then frag[#frag + 1] = decl end

	frag[#frag + 1] = B.assignmentExpression({ name }, { func });
	return B.blockStatement(frag)
end
function match:NilExpression(node)
	return B.literal(nil)
end
function match:PropertyDefinition(node)
	node.value.generator = node.generator
	return self:get(node.value)
end
function match:BlockStatement(node)
	local ret = B.blockStatement(self:list(node.body))
	if node.fileName then
		ret.fileName = node.fileName
	end
	return ret
end
function match:ExpressionStatement(node)
	return B.expressionStatement(self:get(node.expression))
end
function match:CallExpression(node)
	local callee = node.callee
	local args
	if node.arguments.type == "TableExpression" then
		args = { self:get(node.arguments) }
	elseif not node.arguments.type then
		args = self:list(node.arguments, "lookup")
	else
		args = {self:get(node.arguments, "lookup")}
	end
	return B.callExpression(self:get(callee), args)
end
function match:RepeatStatement(node)
	return B.repeatStatement(self:get(node.test, "lookup"), self:get(node.body))
end
function match:WhileStatement(node)
	return B.whileStatement(self:get(node.test, "lookup"), self:get(node.body))
end
function match:ForStatement(node)
	local name = self:get(node.name)
	local init = self:get(node.init, "lookup")
	local last = self:get(node.last, "lookup")
	local step
	if node.step then
		step = self:get(node.step, "lookup")
	else
		step = B.literal(nil)
	end
	local body = self:get(node.body)
	return B.forStatement(B.forInit(name, init), last, step, body)
end
function match:ForInStatement(node)
	local loop = B.identifier(util.genid())
	local save = self.loop
	self.loop = loop

	local none = B.tempnam()
	local temp = B.tempnam()
	local iter = self:list(node.right, "lookup")

	local left = { }
	for i=1, #node.left do
		left[i] = self:get(node.left[i])
	end

	local body =self:get(node.body);
	self.loop = save

	return B.forInStatement(B.forNames(left), iter[1], body)
end

function match:TableExpression(node)
	local properties, unAssigned, usedNos = { }, { }, { }
	for i=1, #node.members do
		local prop = node.members[i]

		local key, val
		if prop.key then
			if prop.key.type == 'Identifier' then
				key = prop.key.name
			elseif prop.key.type == "Literal" then
				key = prop.key.value
				if type(key) == "number" then
					usedNos[key] = key
				end
			end
		else
			if prop.number then
				unAssigned[prop.number.value] = prop.value
			else
				assert(prop.type == "Identifier")
				key = prop.name
			end	
		end

		if not prop.number then
			local desc = properties[key] or nil

			if prop.value then
				desc = self:get(prop.value, "lookup")
			else
				desc = B.identifier(key)
			end

			properties[key] = desc
		end
	end
	
	local j = 1
	for i = 1, #unAssigned do
		while usedNos[j] do j = j+1 end
		local key = j
		usedNos[j] = j
		local desc = self:get(unAssigned[i], "lookup")
		properties[key] = desc
	end

	return B.table(properties)
end
function match:RawString(node)
	local list = { }
	local tostring = B.identifier('tostring')
	for i=1, #node.expressions do
		local expr = node.expressions[i]
		if type(expr) == 'string' then
			list[#list + 1] = B.literal(expr)
		else
			list[#list + 1] = B.callExpression(tostring, { self:get(expr.expression, "lookup") })
		end
	end
	return B.listExpression('..', list)
end


local function countln(istream, pos, idx)
	local line = 0
	local index, limit = idx or 1, pos
	while index <= limit do
		local s, e = string.find(istream , "\n", index, true)
		if s == nil or e > limit then
			break
		end
		index = e + 1
		line  = line + 1
	end
	return line 
end

local function transform(tree)
	local self = { }

	self.ctx = Context.new()
	
	local positions = {}
	local lines = {}
	local inputStreams = {}
	
	local function updateForNewFile(inputStream)
		positions[#positions+1] = 0
		inputStreams[#inputStreams+1] = inputStream
		lines[#lines+1] = 0
	end
	
	local function updateToOldFile()
		positions[#positions] = nil
		inputStreams[#inputStreams] = nil
		lines[#lines] = nil
	end
	

	function self:sync(node)
		local pos = node.pos
		if pos ~= nil and pos > positions[#positions] then
			local prev = positions[#positions]
			local line = countln(inputStreams[#inputStreams], pos, prev + 1) + lines[#lines]
			lines[#lines] = line
			positions[#positions] = pos
		end
	end

	function self:get(node, lookup, ...)
		if not match[node.type] then
			error("no handler for "..tostring(node.type))
		end
		if node.file then
			updateForNewFile(node.file.inputStream)
		end
		self:sync(node)
		local out = match[node.type](self, node, ...)
		if lookup then
			if node.type == "Identifier" and self.ctx:lookup(node.name) ~= notLambda then
				out = makeEval(out)
			end
		end
		out.line = lines[#lines]
		if node.file then
			out.fileName = node.file.name
			updateToOldFile()
		end
		return out
	end

	function self:list(nodes, lookup, ...)
		local list = { }
		for i=1, #nodes do
			list[#list + 1] = self:get(nodes[i], lookup, ...)
		end
		return list
	end
	
	return self:get(tree)
end

return {
	transform = transform
}
