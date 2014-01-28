local test = {}
    
function test:setUp()
    local errors = require"mad.lang.errors"()
    errors:setCurrentChunkName("test")
    self.mod = require"mad.lang.generator.source"(errors)
end

function test:tearDown()
    self.mod = nil
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
