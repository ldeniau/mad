local M = { help={}, test={} }

M.help.self = [[
NAME
  mad.lang.generator.lua

SYNOPSIS
  local source_ctor = require"mad.lang.generator.lua"
  local source      = source_ctor(error_map_instance)
  local source_code = source:generate(ast)
  
DESCRIPTION
  Generates Lua code from an AST.
  
  local source      = source_ctor(error_map_instance)
    Creates a new instance of the source generator, suitable for generating
     one chunk of code.
  local source_code = source:generate(ast)
    Generates Lua-code and maps the output lines to the lines in the AST.
    
RETURN VALUES
  None
  
SEE ALSO
  mad.lang.generator
]]

-- require --------------------------------------------------------------------
local writer        = require"mad.lang.generator.writer"
local options       = require"mad.core.options"
local tableToString = require"lua.tableUtil".stringTable

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
    return call(...)
end

-- module ---------------------------------------------------------------------

local dict = {}

function dict:chunk(node)
    self:render(node.block)
end

function dict:block_stmt(node)
    if node.kind == "do" then self:write("do ") end
    if #node == 1 then
        self:render(node[1])
    else
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
    if node.kind == "do" then
        self.writer:writeln()
        self:write("end ")
    end
end

function dict:assign(node)
    if node.kind == "local" then
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

function dict:funcall(node)
    self:render(node.name)
    if node.kind == ":" then
        self:write(":")
        self:render(node.selfname)
    end
    if #node.arg == 1 and (node.arg[1].ast_id == "literal" and string.find(node.arg[1].value, [=[["'[]]=]) or node.arg[1].ast_id == "tbldef") then
        self:render(node.arg[1])
    else
        self:write("(")
        if node.arg then
            for i,v in ipairs(node.arg) do
                self:render(v)
                if i ~= #node.arg then
                    self:write(", ")
                end
            end
        end
        self:write(")")
    end
end

function dict:label_stmt(node)
    self:write("::")
    self:render(node.name)
    self:write("::")
end

function dict:break_stmt(node)
    self:write("break")
end

function dict:goto_stmt(node)
    self:write("goto ")
    self:render(node.name)
end

function dict:do_stmt(node)
    self:write("do")
    self:render(node.block)
    if #node.block > 1 then self.writer:writeln() end
    self:write(" end")
end

function dict:for_stmt(node)
    self:write("for ")
    self:render(node.name)
    self:write("=")
    self:render(node.first)
    self:write(", ")
    self:render(node.last)
    if node.step then
        self:write(", ")
        self:render(node.step)
    end
    self:write(" do")
    self:render(node.block)
    if #node.block > 1 then self.writer:writeln() end
    self:write(" end")
end

function dict:while_stmt(node)
    self:write("while ")
    self:render(node.expr)
    self:write(" do")
    self:render(node.block)
    if #node.block > 1 then self.writer:writeln() end
    self:write(" end")
end

function dict:repeat_stmt(node)
    self:write("repeat")
    self:render(node.block)
    self.writer:writeln()
    self:write("until ")
    self:render(node.expr)
end

function dict:genfor_stmt(node)
    self:write("for ")
    for i,v in ipairs(node.name) do
        self:render(v)
        if i < #node.name then
            self:write","
        end
    end
    self:write(" in ")
    for i,v in ipairs(node.expr) do
        self:render(v)
        if i < #node.expr then
            self:write","
        end
    end
    self:write(" do")
    self:render(node.block)
    if #node.block > 1 then self.writer:writeln() end
    self:write(" end")
end

local function lambda(self, node)
    self:write([[require"mad.lang.lambda"(function(]])
    if node.param then
        for i,v in ipairs(node.param) do
            self:render(v)
            if i ~= #node.param then
                self:write(",")
            end
        end
    end
    self:write(")")
    self:render(node.block)
    self.writer:writeln()
    self:write("end)")
end

function dict:fundef(node)
    if node.kind == "lambda" and self.lambda then
        lambda(self, node)
        return
    end
    if node.kind == "local" then
        self:write'local '
    end
    self:write("function")
    if node.name then
        self:write' '
        self:render(node.name)
    end
    if node.selfname then
        self:write(":")
        self:render(node.selfname)
    end
    self:write("(")
    if node.param then
        for i,v in ipairs(node.param) do
            self:render(v)
            if i ~= #node.param then
                self:write(",")
            end
        end
    end
    self:write(")")
    self:render(node.block)
    if #node.block > 1 then self.writer:writeln() end
    self:write(" end")
end

function dict:ret_stmt(node)
    self:write("return ")
    for i,v in ipairs(node) do
        self:render(v)
        if i ~= #node then
            self:write(", ")
        end
    end
end

function dict:expr(node)
    for i,v in ipairs(node) do
        if type(v) =="string" then
            if v == 'and' or v == 'or' then
                self:write(" "..v.." ")
            else
                self:write(v)
            end
        else
            self:render(v)
        end
    end
end

function dict:grpexpr(node)
    self:write("(")
    self:render(node.expr)
    self:write(")")
end

function dict:name(node)
    self:write(node.name)
end

function dict:literal(node)
    self:write(node.value)
end

function dict:tbldef(node)
    self:write("{")
    for i,v in ipairs(node) do
        self:render(v)
        if i < #node then
            self:write(", ")
        end
    end
    self:write("}")
end

function dict:tblfld(node)
    if node.kind == "expr" then
        self:write("[")
        self:render(node.key)
        self:write("]=")
    elseif node.kind == "name" then
        self:render(node.key)
        self:write("=")
    end
    self:render(node.value)
end

function dict:tblaccess(node)
    self:render(node.lhs)
    if node.kind == "." then
        self:write(".")
    else
        self:write("[")
    end
    self:render(node.rhs)
    if node.kind ~= "." then
        self:write("]")
    end
end

function dict:if_stmt(node)
    self:write("if ")
    self:render(node[1])
    self:write(" then")
    self:render(node[2])
    self.writer:writeln()
    for i=3, #node, 2 do
        if node[i].ast_id == "block_stmt" then
            self:write("else")
            self:render(node[i])
            self.writer:writeln()
            break
        end
        self:write("elseif ")
        self:render(node[i])
        self:write(" then")
        self:render(node[i+1])
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
        error("don't know what to do with: "..tableToString(node).." on line "..lastline)
    end
    if not dict[node.ast_id] then
        error("no handler for "..node.ast_id)
    end
    if node.fileName then
        self.lastFileName = self.currentFileName
        self.currentFileName = node.fileName
    end
    if node.line then
        self.errors:addToLineMap(node.line, self.writer.line, self.currentFileName)
    end
    local ret = dict[node.ast_id](self, node, ...)
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
    return tostring(self.writer)
end

call = function (_, errors, lambda, ...)
    local self = {
        lambda = lambda or nil,
        errors = errors,
        writer = writer:new(),
        render = render,
        write = write,
        generate = generate
    }
    return self
end

-- test -----------------------------------------------------------------------
M.test = require"mad.lang.generator.test.lua"

-- end  -----------------------------------------------------------------------
return M
