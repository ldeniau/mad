local test = {}
    
function test:setUp()
    self.errors = require"mad.lang.errors"()
    self.errors:setCurrentChunkName("test")
    self.module = require"mad.lang.generator.source"
    self.mod = self.module(self.errors)
end

function test:tearDown()
    self.module = nil
    self.errors = nil
    self.mod = nil
end

function block_stmt(ut)
    self.mod:render{ ast_id = "block_stmt",
                        { ast_id = "break_stmt" },
                        { ast_id = "break_stmt" },
                        { ast_id = "break_stmt" }  }
    ut:equals(tostring(self.mod.writer),
[[  break
    break
    break]])
end
function block_stmtDo(ut)
    self.mod:render{ ast_id = "block_stmt", kind = "do",
                        { ast_id = "break_stmt" },
                        { ast_id = "break_stmt" },
                        { ast_id = "break_stmt" }  }
    ut:equals(tostring(self.mod.writer),
[[do
    break
    break
    break
end]])
end

function test:break_stmt(ut)
    self.mod:render{ ast_id = "break_stmt" }
    ut:equals(tostring(self.mod.writer),
[[break]])
end

function test:goto_stmt(ut)
    self.mod:render{ ast_id = "goto_stmt", name = { ast_id = "name", name = "name" } }
    ut:equals(tostring(self.mod.writer),
[[goto name]])
end


function test:label_stmt(ut)
    self.mod:render{ ast_id = "label_stmt", name = { ast_id = "name", name = "name" } }
    ut:equals(tostring(self.mod.writer),
[[::name::]])
end

function test:repeat_stmt(ut)
    self.mod:render{ ast_id = "repeat_stmt", block = { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        expr = { ast_id = "literal", value = "1" } }
    ut:equals(tostring(self.mod.writer),
[[repeat
    break
until 1]])
end

function test:while_stmt(ut)
    self.mod:render{ ast_id = "while_stmt", block = { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        expr = { ast_id = "literal", value = "1" } }
    ut:equals(tostring(self.mod.writer),
[[while 1 do
    break
end]])
end

function test:for_stmtStep(ut)
    self.mod:render{ ast_id = "for_stmt", block = { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        name  = { ast_id = "name",    name  = "a" },
                        first = { ast_id = "literal", value = "1" },
                        last  = { ast_id = "literal", value = "2" },
                        step  = { ast_id = "literal", value = "3" } }
    ut:equals(tostring(self.mod.writer),
[[for a = 1, 2, 3 do
    break
end]])
end
function test:for_stmt(ut)
    self.mod:render{ ast_id = "for_stmt", block = { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        name  = { ast_id = "name",    name  = "a" },
                        first = { ast_id = "literal", value = "1" },
                        last  = { ast_id = "literal", value = "2" } }
    ut:equals(tostring(self.mod.writer),
[[for a = 1, 2 do
    break
end]])
end

function test:genfor_stmtMltpl(ut)
    self.mod:render{ ast_id = "genfor_stmt", block = { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        name = { { ast_id = "name",    name  = "a" }, { ast_id = "name",    name  = "b" } },
                        expr = { { ast_id = "literal", value = "1" }, { ast_id = "literal", value = "2" } } }
    ut:equals(tostring(self.mod.writer), 
[[for a, b in 1, 2 do
    break
end]])
end
function test:genfor_stmt(ut)
    self.mod:render{ ast_id = "genfor_stmt", block = { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        name = { { ast_id = "name",    name  = "a" } },
                        expr = { { ast_id = "literal", value = "1" } } }
    ut:equals(tostring(self.mod.writer), 
[[for a in 1 do
    break
end]])
end

function test:ifstmt(ut)
    self.mod:render{ ast_id = "if_stmt",
                        { ast_id = "literal", value = "true" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        { ast_id = "literal", value = "false" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        { ast_id = "literal", value = "true" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), 
[[if true then
    break
elseif false then
    break
elseif true then
    break
else
    break
end]])
end
function test:ifstmtNoElseif(ut)
    self.mod:render{ ast_id = "if_stmt",
                        { ast_id = "literal", value = "true" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), 
[[if true then
    break
else
    break
end]])
end
function test:ifstmtNoElse(ut)
    self.mod:render{ ast_id = "if_stmt",
                        { ast_id = "literal", value = "true" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        { ast_id = "literal", value = "false" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } },
                        { ast_id = "literal", value = "true" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), 
[[if true then
    break
elseif false then
    break
elseif true then
    break
end]])
end
function test:ifstmt(ut)
    self.mod:render{ ast_id = "if_stmt",
                        { ast_id = "literal", value = "true" },
                        { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), 
[[if true then
    break
end]])
end

function test:retstmt(ut)
    self.mod:render{ ast_id = "ret_stmt", { ast_id = "literal", value = 1 } }
    ut:equals(tostring(self.mod.writer), [[return 1]])
end
function test:retstmtmltpl(ut)
    self.mod:render{ ast_id = "ret_stmt", { ast_id = "literal", value = 1 }, { ast_id = "literal", value = 2 } }
    ut:equals(tostring(self.mod.writer), [[return 1, 2]])
end

function test:assign(ut)
    self.mod:render{ ast_id = "assign",
                        lhs = {{ ast_id = "name", name = "a" }},
                        rhs = {{ ast_id = "name", name = "b" }} }
    ut:equals(tostring(self.mod.writer),  [[a = b]])
end
function test:assignMany(ut)
    self.mod:render{ ast_id = "assign",
                        lhs = {{ ast_id = "name", name = "a" }, { ast_id = "name",    name  = "c" }},
                        rhs = {{ ast_id = "name", name = "b" }, { ast_id = "literal", value = "1" }} }
    ut:equals(tostring(self.mod.writer),  [[a, c = b, 1]])
end
function test:assignLocal(ut)
    self.mod:render{ ast_id = "assign", kind = "local",
                        lhs = {{ ast_id = "name", name = "a" }},
                        rhs = {{ ast_id = "name", name = "b" }} }
    ut:equals(tostring(self.mod.writer),  [[local a = b]])
end

function test:expr(ut)
self.mod:render{ ast_id = "expr",
                   { ast_id = "name", name = "a"},
                   "+",
                   { ast_id = "name", name = "b" } }
    ut:equals(tostring(self.mod.writer),  [[a + b]])
end
function test:exprTree(ut)
    self.mod:render{ ast_id = "expr",
                       { ast_id = "name", name = "a"},
                       "+",
                       { ast_id = "name", name = "b" },
                       "+",
                       { ast_id = "expr",
                           { ast_id = "name", name = "c" },
                           "*",
                           { ast_id = "name", name = "d" }} }
    ut:equals(tostring(self.mod.writer),  [[a + b + c * d]])
end

function test:tblaccessDot(ut)
    self.mod:render{ ast_id = "tblaccess", kind = ".",
                         lhs = { ast_id = "name", name = "a"},
                         rhs = { ast_id = "name", name = "b" } }
    ut:equals(tostring(self.mod.writer),  [[a.b]])
end
function test:tblaccess(ut)
    self.mod:render{ ast_id = "tblaccess", kind = nil,
                         lhs = { ast_id = "name", name = "a"},
                         rhs = { ast_id = "name", name = "b" } }
    ut:equals(tostring(self.mod.writer),  [=[a[b]]=])
end

function test:funcall(ut)
    self.mod:render{ ast_id = "funcall",
                         name = { ast_id = "name", name = "a"},
                         arg = {},
                         kind = nil}
    ut:equals(tostring(self.mod.writer),  [[a(  )]])
end
function test:funcallTwoArg(ut)
    self.mod:render{ ast_id = "funcall",
                         name = { ast_id = "name", name = "a"},
                         arg = { { ast_id = "literal", value = "1" }, { ast_id = "literal", value = "..." }},
                         kind = nil}
    ut:equals(tostring(self.mod.writer),  [[a( 1, ... )]])
end
function test:funcallMultiname(ut)
    self.mod:render{ ast_id = "funcall",
                         name = { ast_id = "tblaccess", kind = ".",
                            lhs = { ast_id = "name", name = "a"},
                            rhs = { ast_id = "name", name = "b" } },
                         arg = {},
                         kind = nil}
    ut:equals(tostring(self.mod.writer),  [[a.b(  )]])
end
function test:funcallSelfname(ut)
    self.mod:render{ ast_id = "funcall",
                         name = { ast_id = "tblaccess", kind = ".",
                            lhs = { ast_id = "name", name = "a"},
                            rhs = { ast_id = "name", name = "b" } },
                         selfname = { ast_id = "name", name = "c" },
                         arg = {},
                         kind = ":"}
    ut:equals(tostring(self.mod.writer),  [[a.b:c(  )]])
end

function test:grpexpr(ut)
    self.mod:render{ ast_id = "grpexpr", expr = { ast_id = "literal", value = "1" } }
    ut:equals(tostring(self.mod.writer), [[( 1 )]])
end

function test:lambda_unsafe(ut)
    local generator = self.module(self.errors,true)
    generator:render{ ast_id = "fundef", kind = "lambda", param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(generator.writer), [[
require"mad.lang.lambda"( function ( a, b )
    break
end )]])
end

function test:lambda(ut)
    self.mod:render{ ast_id = "fundef", kind = "lambda", param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function ( a, b )
    break
end]])
end
function test:fundef_a(ut)
    self.mod:render{ ast_id = "fundef", param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function ( a, b )
    break
end]])
end
function test:fundef_n(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname( a, b )
    break
end]])
end
function test:fundef_nEllipsis(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" }, { ast_id = "literal", value = "..." } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname( a, b, ... )
    break
end]])
end
function test:fundef_nOnlyEllipsis(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "literal", value = "..." } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname( ... )
    break
end]])
end
function test:fundef_nEmpty(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = {}, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname(  )
    break
end]])
end
function test:fundef_nDotName(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "tblaccess", lhs = { ast_id = "name", name = "a"}, rhs = { ast_id = "name", name = "b" }, kind = "." }, param = {}, selfname = { ast_id = "name", name = "c" }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function a.b:c(  )
    break
end]])
end
function test:fundef_l(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } }, kind = "local" }
    ut:equals(tostring(self.mod.writer), [[
local function funname( a, b )
    break
end]])
end

function test:tbldef(ut)
    self.mod:render{ ast_id = "tbldef", { ast_id = "tblfld", value = { ast_id = "literal", value = "1" } }}
    ut:equals(tostring(self.mod.writer), [[{ 1 }]])
end
function test:tbldefEmpty(ut)
    self.mod:render{ ast_id = "tbldef" }
    ut:equals(tostring(self.mod.writer), [[{  }]])
end

function test:tblfldNoKey(ut)
    self.mod:render{ ast_id = "tblfld", value = { ast_id = "literal", value = "1" } }
    ut:equals(tostring(self.mod.writer), [[1]])
end
function test:tblfldKeySqrBrckt(ut)
    self.mod:render{ ast_id = "tblfld", value = { ast_id = "literal", value = "1" }, key = { ast_id = "literal", value = "1" }, kind = "expr" }
    ut:equals(tostring(self.mod.writer), [=[[1] = 1]=])
end
function test:tblfldKeyDot(ut)
    self.mod:render{ ast_id = "tblfld", value = { ast_id = "literal", value = "1" }, key = { ast_id = "name", name = "hello" }, kind = "name" }
    ut:equals(tostring(self.mod.writer), [[hello = 1]])
end

function test:literal(ut)
    self.mod:render{ ast_id = "literal", value = '"hello"'}
    ut:equals(tostring(self.mod.writer), [["hello"]])
end

function test:name(ut)
    self.mod:render{ ast_id = "name", name = "hello"}
    ut:equals(tostring(self.mod.writer), [[hello]])
end

function test:write(ut)
    self.mod:write("Yo")
    ut:equals(tostring(self.mod.writer),"Yo")
end


return test
