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

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
    return call(...)
end

-- module ---------------------------------------------------------------------

local match = {}

function match:chunk(node)
    self:render(node[1])
end

function match:block(node)
    self.writer:indent()
    self.writer:writeln()
    for i=1, #node do
        self:render(node[i])
        if i ~= #node then 
            self.writer:writeln()
        end
    end
    self.writer:undent()
end

function match:assign(node)
    if node.localdef then
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
        for i = 1, #node.rhs do
            self:render(node.rhs[i])
            if i < #node.rhs then
                self:write(", ")
            end
        end
    end
end

function match:call(node)
    self:render(node.callee)
    if node.selfExp then
        self:write(":")
        self:render(node.selfExp)
    end
    self:write("( ")
    if node.arguments then
        for i,v in ipairs(node.arguments) do
            self:render(v)
            if i ~= #node.arguments then
                self:write(", ")
            end
        end
    end
    self:write(" )")
end

function match:label(node)
    self:write("::")
    self:render(node[1])
    self:write("::")
end

function match:breakstmt(node)
    self:write("break")
end

function match:gotostmt(node)
    self:write("goto ")
    self:render(node[1])
end

function match:dostmt(node)
    self:write("do ")
    self:render(node[1])
    self.writer:writeln()
    self:write("end")
end

function match:loop(node)
    if node.kind == "for" then
        self:write("for ")
        self:render(node.name)
        self:write(" = ")
        self:render(node.first)
        self:write(", ")
        self:render(node.last)
        if node.step then
            self:write(", ")
            self:render(node.step)
        end
        self:write(" do ")
        self:render(node[1])
        self.writer:writeln()
        self:write("end")
    elseif node.kind == "while" then
        self:write("while ")
        self:render(node.test)
        self:write(" do ")
        self:render(node[1])
        self.writer:writeln()
        self:write("end")
    elseif node.kind == "repeat" then
        self:write("repeat ")
        self:render(node[1])
        self.writer:writeln()
        self:write("until ")
        self:render(node.test)
    else
        error("Not sure what to do with this node.",2)
    end
end

function match:genericfor(node)
    self:write("for ")
    for i,v in ipairs(node.names) do
        self:render(v)
        if i < #node.names then
            self:write", "
        end
    end
    self:write(" in ")
    for i,v in ipairs(node.expressions) do
        self:render(v)
        if i < #node.expressions then
            self:write", "
        end
    end
    self:write(" do ")
    self:render(node[1])
    self.writer:writeln()
    self:write("end")
end

function match:fundef(node)
    if node.localdef then
        self:write("local ")
    end
    self:write("function ")
    if node.name then
        self:render(node.name)
    end
    self:write("( ")
    if node.parameters then
        for i,v in ipairs(node.parameters) do
            self:render(v)
            if i ~= #node.parameters then
                self:write(", ")
            end
        end
    end
    self:write(" )")
    self:render(node[1])
    self.writer:writeln()
    self:write("end")
end

function match:returnstmt(node)
    self:write("return ")
    for i,v in ipairs(node) do
        self:render(v)
        if i ~= #node then
            self:write(", ")
        end
    end
end

function match:expr(node)
    for i,v in ipairs(node) do
        if type(v) =="string" then
            self:write(" "..v.." ")
        else
            self:render(v)
        end
    end
end

function match:groupexp(node)
    self:write("( ")
    self:render(node[1])
    self:write(" )")
end

function match:name(node)
    self:write(node[1])
end

function match:literal(node)
    self:write(node[1])
end

function match:tabledef(node)
    self:write("{ ")
    for i,v in ipairs(node) do
        self:render(v)
        if i < #node then
            self:write(", ")
        end
    end
    self:write(" }")
end

function match:field(node)
    if node.operator == "[" then
        self:write("[")
    end
    if node.key then
        self:render(node.key)
    end
    if node.operator then
        self:write(node.operator)
    end
    if node.key then
        self:write(" = ")
    end
    self:render(node.value)
end

function match:tblaccess(node)
    self:render(node.lhs)
    if node.literalidx then
        self:write(".")
    elseif node.selfdef then
        self:write(":")
    else
        self:write("[")
    end
    self:render(node.rhs)
    if not node.literalidx and not node.selfdef then
        self:write("]")
    end
end

function match:ifstmt(node)
    self:write("if ")
    self:render(node.test)
    self:write(" then")
    self:render(node[1])
    self.writer:writeln()
    for i=1, #node.elseifTable, 2 do
        self:write("elseif ")
        self:render(node.elseifTable[i])
        self:write(" then")
        self:render(node.elseifTable[i+1])
        self.writer:writeln()
    end
    if node.elseBlock then
        self:write("else")
        self:render(node.elseBlock)
        self.writer:writeln()
    end
    self:write("end")
end

local lastline = 0
local function render(self, node, ...)
    if node and node.line then
        lastline = node.line
    end
    if type(node) ~= "table" then
        error("not a table: "..tostring(node).." on line "..lastline)
    end
    if not node.ast_id then
        error("don't know what to do with: "..require"lua.tableUtil".stringTable(node).." on line "..lastline)
    end
    if not match[node.ast_id] then
        error("no handler for "..node.ast_id)
    end
    if node.fileName then
        self.lastFileName = self.currentFileName
        self.currentFileName = node.fileName
    end
    if node.line then
        self.errors:addToLineMap(node.line, self.writer.line, self.currentFileName)
    end
    local ret = match[node.ast_id](self, node, ...)
    if node.fileName then
        self.currentFileName = self.lastFileName
    end
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

call = function (_, errors, ...)
    local self = {
        errors = errors,
        writer = writer:new(),
        render = render,
        write = write,
        generate = generate
    }
    return self
end

-- test -----------------------------------------------------------------------
function M.test:setUp()
    self.writer = writer:new()
    self.render = render
    self.write = write
    self.generate = generate
    local errors = require"mad.lang.errors"()
    errors:setCurrentChunkName("test")
    self.errors = errors
end

function M.test:tearDown()
    self.writer = nil
    self.render = nil
    self.write = nil
    self.generate = nil
    self.errors = nil
end

function M.test:Chunk(ut)
end

function M.test:Block(ut)
end

function M.test:Assignment(ut)
end

function M.test:FunctionCall(ut)
end

function M.test:Label(ut)
end

function M.test:Break(ut)
end

function M.test:Goto(ut)
end

function M.test:Do(ut)
end

function M.test:Loop(ut)
end

function M.test:GenericFor(ut)
end

function M.test:FunctionDefinition(ut)
end

function M.test:Return(ut)
end

function M.test:Vararg(ut)
end

function M.test:BinaryExpression(ut)
end

function M.test:UnaryExpression(ut)
end

function M.test:Variable(ut)
end

function M.test:Literal(ut)
end

function M.test:Table(ut)
end

function M.test:If(ut)
end

function M.test:render(self, node, ...)
end

function M.test:write(ut)
    self:write("Yo")
    ut:equals(tostring(self.writer),"Yo")
end

function M.test:generate (self, tree)
end

-- end  -----------------------------------------------------------------------
return M
