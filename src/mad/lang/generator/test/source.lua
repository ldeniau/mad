local Mod = {}
local mt = {}; setmetatable(Mod, mt)
mt.__call = function (_, M)
    
function M.test:setUp()
    local errors = require"mad.lang.errors"()
    errors:setCurrentChunkName("test")
    self.mod = M(errors)
end

function M.test:tearDown()
    self.mod = nil
end

function M.test:grpexpr(ut)
    self.mod:render{ ast_id = "grpexpr", expr = { ast_id = "literal", value = "1" } }
    ut:equals(tostring(self.mod.writer), [[( 1 )]])
end

function M.test:fundef_a(ut)
    self.mod:render{ ast_id = "fundef", param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function ( a, b )
    break
end]])
end
function M.test:fundef_n(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname( a, b )
    break
end]])
end
function M.test:fundef_nEllipsis(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" }, { ast_id = "literal", value = "..." } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname( a, b, ... )
    break
end]])
end
function M.test:fundef_nOnlyEllipsis(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "literal", value = "..." } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname( ... )
    break
end]])
end
function M.test:fundef_nEmpty(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = {}, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function funname(  )
    break
end]])
end
function M.test:fundef_nDotName(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "tblaccess", lhs = { ast_id = "name", name = "a"}, rhs = { ast_id = "name", name = "b" }, kind = "." }, param = {}, selfname = { ast_id = "name", name = "c" }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } } }
    ut:equals(tostring(self.mod.writer), [[
function a.b:c(  )
    break
end]])
end
function M.test:fundef_l(ut)
    self.mod:render{ ast_id = "fundef", name = { ast_id = "name", name = "funname" }, param = { { ast_id = "name", name = "a" }, { ast_id = "name", name = "b" } }, block = { ast_id = "block_stmt", { ast_id = "break_stmt" } }, kind = "local" }
    ut:equals(tostring(self.mod.writer), [[
local function funname( a, b )
    break
end]])
end

function M.test:tbldef(ut)
    self.mod:render{ ast_id = "tbldef", { ast_id = "tblfld", value = { ast_id = "literal", value = "1" } }}
    ut:equals(tostring(self.mod.writer), [[{ 1 }]])
end
function M.test:tbldefEmpty(ut)
    self.mod:render{ ast_id = "tbldef" }
    ut:equals(tostring(self.mod.writer), [[{  }]])
end

function M.test:tblfldNoKey(ut)
    self.mod:render{ ast_id = "tblfld", value = { ast_id = "literal", value = "1" } }
    ut:equals(tostring(self.mod.writer), [[1]])
end
function M.test:tblfldKeySqrBrckt(ut)
    self.mod:render{ ast_id = "tblfld", value = { ast_id = "literal", value = "1" }, key = { ast_id = "literal", value = "1" }, kind = "expr" }
    ut:equals(tostring(self.mod.writer), [=[[1] = 1]=])
end
function M.test:tblfldKeyDot(ut)
    self.mod:render{ ast_id = "tblfld", value = { ast_id = "literal", value = "1" }, key = { ast_id = "name", name = "hello" }, kind = "name" }
    ut:equals(tostring(self.mod.writer), [[hello = 1]])
end

function M.test:literal(ut)
    self.mod:render{ ast_id = "literal", value = '"hello"'}
    ut:equals(tostring(self.mod.writer), [["hello"]])
end

function M.test:name(ut)
    self.mod:render{ ast_id = "name", name = "hello"}
    ut:equals(tostring(self.mod.writer), [[hello]])
end

function M.test:write(ut)
    self.mod:write("Yo")
    ut:equals(tostring(self.mod.writer),"Yo")
end


end

return Mod
