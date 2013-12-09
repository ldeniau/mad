local M = { help={}, test={} }

M.help.self = [[
NAME
  source

SYNOPSIS
  local source = require"mad.lang.generator.source"

DESCRIPTION
  

RETURN VALUES
  

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local writer = require"mad.lang.generator.writer"
local options = require"mad.core.options"
local testApi = require"mad.test.api"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

local match = {}

function match:Chunk(node)
	for i=1, #node.body do
		self:render(node.body[i])
		self.writer:writeln()
	end
end

function match:Block(node)
	self.writer:indent()
	self.writer:writeln()
	for i=1, #node.body do
		self:render(node.body[i])
		if i ~= #node.body then 
			self.writer:writeln()
		end
	end
	self.writer:undent()
end

function match:Assignment(node)
	if node.localAssignment then
		self:write("local ")
	end
	for i = 1, #node.lhs do
		self:render(node.lhs[i])
		if i < #node.lhs then
			self:write(", ")
		end
	end
	if node.rhs then
		self:write(" = ")
	end
	for i = 1, #node.rhs do
		self:render(node.rhs[i])
		if i < #node.rhs then
			self:write(", ")
		end
	end
end

function match:FunctionCall(node)
	self:render(node.callee)
	self:write("( ")
	for i,v in ipairs(node.arguments) do
		self:render(v)
		if i ~= #node.arguments then
			self:write(", ")
		end
	end
	self:write(" )")
end

function match:Label(node)
	self:write("::"..node.name.."::")
end

function match:Break(node)
	self:write("break")
end

function match:Goto(node)
	self:write("goto ")
	self:render(node.name)
end

function match:Do(node)
	self:write("do")
	self:render(node.body)
	self.writer:writeln()
	self:write("end")
end

function match:Loop(node)
	if node.kind == "For" then
		self:write("for ")
		self:render(node.name)
		self:write(" = ")
		self:render(node.init)
		self:write(", ")
		self:render(node.last)
		if node.step then
			self:write(", ")
			self:render(node.step)
		end
		self:write("do")
		self:render(node.body)
		self.writer:writeln()
		self:write("end")
	elseif node.kind == "While" then
		self:write("while ")
		self:render(node.test)
		self:write(" do")
		self:render(node.body)
		self.writer:writeln()
		self:write("end")
	elseif node.kind == "Repeat" then
		self:write("repeat ")
		self:render(node.body)
		self.writer:writeln()
		self:write("until ")
		self:render(node.test)
	else
		error("Not sure what to do with this node.",2)
	end
end

function match:GenericFor(node)
	self:write("for" )
	for _,v in ipairs(node.names) do
		self:render(v)
		self:write", "
	end
	self:write(" in ")
	for _,v in ipairs(node.expressions) do
		self:render(v)
		self:write", "
	end
	self:write(" do")
	self:render(node.body)
	self.writer:writeln()
	self:write("end")
end

function match:FunctionDefinition(node)
	if node.localDeclaration then
		self:write("local ")
	end
	self:write("function ")
	if node.id then
		self:render(node.id)
	end
	self:write("( ")
	for i,v in ipairs(node.arguments) do
		self:render(v)
		if i ~= #node.arguments then
			self:write(", ")
		end
	end
	self:write(" )")
	self:render(node.body)
	self.writer:writeln()
	self:write("end")
end

function match:Return(node)
	self:write("return ")
	for i,v in ipairs(node.values) do
		self:render(v)
		if i ~= #node.values then
			self:write(", ")
		end
	end
end

function match:Vararg(node)
	self:write("...")
end

function match:BinaryExpression(node)
	self:render(node.lhs)
	self:write(node.operator)
	self:render(node.rhs)
end

function match:UnaryExpression(node)
	self:write(node.operator)
	self:render(node.argument)
end

function match:Variable(node)
	self:write(node.name)
end

function match:Literal(node)
print(type(node.value))
	if type(node.value) == "string" then
		self:write'"'
		self:write(tostring(node.value))
		self:write'"'
	elseif type(node.value) == "boolean" then
		if node.value then
			self:write("true")
		else
			self:write("false")
		end
	elseif type(node.value) == "number" then
		self:write(tostring(node.value))
	end
end

function match:Table(node)
	self:write("{ ")
	for i,v in ipairs(node.implicitExpression) do
		self:render(v)
		if #node.explicitExpression > 0 or i ~= #node.implicitExpression then
			self:write(", ")
		end
	end
	for i,v in ipairs(node.explicitExpression) do
		self:render(v)
		if i ~= #node.explicitExpression then
			self:write(", ")
		end
	end
	self:write(" }")
end

function match:If(node)
	self:write("if ")
	self:render(node.test)
	self:write(" then")
	self.writer:writeln()
	self.writer:indent()
	self:render(node.consequent)
	self.writer:undent()
	self:write("else")
	self.writer:writeln()
	self.writer:indent()
	self:render(node.alternate)
	self.writer:undent()
	self:write("end")
end

local function render(self, node, ...)
	if type(node) ~= "table" then
		error("not a table: "..tostring(node))
	end
	if not node.type then
		error("don't know what to do with: "..util.dump(node))
	end
	if not match[node.type] then
		error("no handler for "..node.type)
	end
	local ret = match[node.type](self, node, ...)
	
	return ret
end

local function write(self, str)
	self.writer:write(str)
end

local function generate (self, tree)
	local code = self:render(tree)
	if options.dumpSource then
		print(tostring(self.writer))
	end
	return tostring(self.writer)
end

call = function (_, ...)
	local self = {
		writer = writer:new(),
		render = render,
		write = write,
		generate = generate
	}
	return self
end

-- test -----------------------------------------------------------------------
function M.test:setUp()

end

function M.test:tearDown()

end

function M.test:Chunk(node)
end

function M.test:Block(node)
end

function M.test:Assignment(node)
end

function M.test:FunctionCall(node)
end

function M.test:Label(node)
end

function M.test:Break(node)
end

function M.test:Goto(node)
end

function M.test:Do(node)
end

function M.test:Loop(node)
end

function M.test:GenericFor(node)
end

function M.test:FunctionDefinition(node)
end

function M.test:Return(node)
end

function M.test:Vararg(node)
end

function M.test:BinaryExpression(node)
end

function M.test:UnaryExpression(node)
end

function M.test:Variable(node)
end

function M.test:Literal(node)
end

function M.test:Table(node)
end

function M.test:If(node)
end

function M.test:render(self, node, ...)
end

function M.test:write(self, str)
end

function M.test:generate (self, tree)
end

-- end  -----------------------------------------------------------------------
return M
