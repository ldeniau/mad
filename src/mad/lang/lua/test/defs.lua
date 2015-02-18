local M = {}

function M:setUp()
    self.defs = require"mad.lang.lua.defs".defs
end

function M:tearDown()
    self.defs = nil
end

function M:error( ut )
    ut:fails(self.defs.error,[[a = 1]], 0)
end

function M:chunk(ut) 
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.chunk, body)
    ut:equals(res.ast_id, "chunk")
    ut:equals(res.block, body)
end

function M:block(ut)
    local res = ut:succeeds(self.defs.block,"dummy", {ast_id = "break_stmt"}, {ast_id = "label_stmt", name = {ast_id = "name", name = "name"}})
    ut:equals(res.ast_id, "block_stmt")
    ut:equals(res[1].ast_id, "break_stmt")
    ut:equals(res[2].ast_id, "label_stmt")
    ut:equals(#res, 2)
end

function M:breakstmt(ut)
    local res = ut:succeeds(self.defs.breakstmt)
    ut:equals(res.ast_id, "break_stmt")
    ut:equals(#res, 0)
end

function M:gotostmt(ut)
    local res = ut:succeeds(self.defs.gotostmt, { ast_id = "name", name = "name"})
    ut:equals(res.ast_id, "goto_stmt")
    ut:equals(res.name.name, "name")
end

function M:dostmt(ut)
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.dostmt, body)
    ut:equals(res.ast_id, "block_stmt")
    ut:equals(res.kind, "do")
    ut:equals(res[1].ast_id, "break_stmt")
end

function M:assign(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.assign, {n"a",n"b"},{n"c",n"d"})
    ut:equals(res.ast_id, "assign")
    ut:equals(res.kind, nil)
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.rhs[1].name, "c")
    ut:equals(res.rhs[2].name, "d")
    res = ut:succeeds(self.defs.assign, {n"a"},{n"c"})
    ut:equals(res.ast_id, "assign")
    ut:equals(res.kind, nil)
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].name, "c")
end

function M:locassign(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.locassign, {n"a",n"b"},{n"c",n"d"})
    ut:equals(res.ast_id, "assign")
    ut:equals(res.kind, "local")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.rhs[1].name, "c")
    ut:equals(res.rhs[2].name, "d")
    res = ut:succeeds(self.defs.locassign, {n"a",n"b"})
    ut:equals(res.ast_id, "assign")
    ut:equals(res.kind, "local")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.rhs, nil)
    res = ut:succeeds(self.defs.locassign, {n"a"},{n"c"})
    ut:equals(res.ast_id, "assign")
    ut:equals(res.kind, "local")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].name, "c")
end

function M:whilestmt(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.whilestmt, n"a",body)
    ut:equals(res.ast_id, "while_stmt")
    ut:equals(res.expr.name, "a")
    ut:equals(res.block, body)
end

function M:repeatstmt(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.repeatstmt,body, n"a")
    ut:equals(res.ast_id, "repeat_stmt")
    ut:equals(res.expr.name, "a")
    ut:equals(res.block, body)
end

function M:ifstmt(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.ifstmt, "dummy", n"a",body,n"b",body,n"c",body,body)
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], body)
    ut:equals(res[3].name, "b")
    ut:equals(res[4], body)
    ut:equals(res[5].name, "c")
    ut:equals(res[6], body)
    ut:equals(res[7], body)
    res = ut:succeeds(self.defs.ifstmt, "dummy", n"a",body,body)
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], body)
    ut:equals(res[3], body)
    res = ut:succeeds(self.defs.ifstmt, "dummy", n"a",body,n"b",body,n"c",body)
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], body)
    ut:equals(res[3].name, "b")
    ut:equals(res[4], body)
    ut:equals(res[5].name, "c")
    ut:equals(res[6], body)
    res = ut:succeeds(self.defs.ifstmt, "dummy", n"a",body)
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], body)
end

function M:forstmt(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.forstmt, n"a", n"b", n"c", n"d", body)
    ut:equals(res.ast_id, "for_stmt")
    ut:equals(res.block, body)
    ut:equals(res.name.name, "a")
    ut:equals(res.first.name, "b")
    ut:equals(res.last.name, "c")
    ut:equals(res.step.name, "d")
    res = ut:succeeds(self.defs.forstmt, n"a", n"b", n"c", body)
    ut:equals(res.ast_id, "for_stmt")
    ut:equals(res.block, body)
    ut:equals(res.name.name, "a")
    ut:equals(res.first.name, "b")
    ut:equals(res.last.name, "c")
    ut:equals(res.step, nil)
end

function M:forinstmt(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.forinstmt, {n"a"}, {n"b"}, body)
    ut:equals(res.ast_id, "genfor_stmt")
    ut:equals(res.block, body)
    ut:equals(res.name[1].name, "a")
    ut:equals(res.expr[1].name, "b")
end

function M:retstmt(ut)
    local res = ut:succeeds(self.defs.retstmt, "dummy")
    ut:equals(res.ast_id, "ret_stmt")
    ut:equals(#res, 0)
    res = ut:succeeds(self.defs.retstmt, "dummy", {ast_id = "name", name = "a"}, {ast_id = "name", name = "b"})
    ut:equals(res.ast_id, "ret_stmt")
    ut:equals(#res, 2)
    ut:equals(res[1].name, "a")
    ut:equals(res[2].name, "b")
end

function M:label(ut)
    local res = ut:succeeds(self.defs.label, "dummy", {ast_id = "name", name = "a"})
    ut:equals(res.ast_id, "label_stmt")
    ut:equals(res.name.name, "a")
end

function M:orexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.orexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.orexp, "dummy", n"a", "or", n"b", "or", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "or")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "or")
    ut:equals(res[5].name, "c")
end

function M:powexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.powexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.powexp, "dummy", n"a", "^", n"b", "^", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "^")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "^")
    ut:equals(res[5].name, "c")
end

function M:andexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.andexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.andexp, "dummy", n"a", "and", n"b", "and", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "and")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "and")
    ut:equals(res[5].name, "c")
end

function M:logexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.logexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.logexp, "dummy", n"a", "<", n"b", ">", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "<")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], ">")
    ut:equals(res[5].name, "c")
end

function M:catexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.catexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.catexp, "dummy", n"a", "..", n"b", "..", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "..")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "..")
    ut:equals(res[5].name, "c")
end

function M:sumexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.sumexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.sumexp, "dummy", n"a", "+", n"b", "-", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "+")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "-")
    ut:equals(res[5].name, "c")
end

function M:prodexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.prodexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.prodexp, "dummy", n"a", "*", n"b", "/", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "*")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "/")
    ut:equals(res[5].name, "c")
end

function M:unexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.unexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.unexp, "dummy", "-", "#", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1], "-")
    ut:equals(res[2], "#")
    ut:equals(res[3].name, "c")
end

function M:powexp(ut)
    local e = function(...) return { ast_id = "expr", ... } end
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.powexp, "dummy", n"a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.powexp, "dummy", n"a", "^", n"b", "^", n"c")
    ut:equals(res.ast_id, "expr")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], "^")
    ut:equals(res[3].name, "b")
    ut:equals(res[4], "^")
    ut:equals(res[5].name, "c")
end

function M:varexp(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local res = ut:succeeds(self.defs.varexp, n"a")
    ut:equals(res.name, "a")
    res = ut:succeeds(self.defs.varexp, n"a", ".", n"b", ".", n"c")
    ut:equals(res.ast_id, "tblaccess")
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "c")
    ut:equals(res.lhs.ast_id, "tblaccess")
    ut:equals(res.lhs.kind, ".")
    ut:equals(res.lhs.rhs.name, "b")
    ut:equals(res.lhs.lhs.name, "a")
    res = ut:succeeds(self.defs.varexp, n"a", "[", n"b", ".", n"c")
    ut:equals(res.ast_id, "tblaccess")
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "c")
    ut:equals(res.lhs.ast_id, "tblaccess")
    ut:equals(res.lhs.kind, nil)
    ut:equals(res.lhs.rhs.name, "b")
    ut:equals(res.lhs.lhs.name, "a")
    res = ut:succeeds(self.defs.varexp, n"a", "(", {n"b"}, ".", n"c")
    ut:equals(res.ast_id, "tblaccess")
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "c")
    ut:equals(res.lhs.ast_id, "funcall")
    ut:equals(res.lhs.kind, nil)
    ut:equals(res.lhs.arg[1].name, "b")
    ut:equals(res.lhs.name.name, "a")
    res = ut:succeeds(self.defs.varexp, n"a", ":", n"b", "(", {n"c"})
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.kind, ":")
    ut:equals(res.arg[1].name, "c")
    ut:equals(res.selfname.name, "b")
    ut:equals(res.name.name, "a")
end

function M:grpexp(ut)
    local res = ut:succeeds(self.defs.grpexp, { ast_id = "literal", value = "1" })
    ut:equals(res.expr.ast_id, "literal")
    ut:equals(res.expr.value, "1")
end

function M:fundef_a(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.fundef_a, {}, body)
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.kind, nil)
    ut:equals(res.name, nil)
    ut:equals(res.selfname, nil)
    ut:equals(#res.param, 0)
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M:fundef_n(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.fundef_n, n"a", {}, body)
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.kind, nil)
    ut:equals(res.name.name, "a")
    ut:equals(res.selfname, nil)
    ut:equals(#res.param, 0)
    ut:equals(res.block[1].ast_id, "break_stmt")
    res = ut:succeeds(self.defs.fundef_n, n"a", n"b", {}, body)
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.kind, nil)
    ut:equals(res.name.name, "a")
    ut:equals(res.selfname.name, "b")
    ut:equals(#res.param, 0)
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M:fundef_l(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local body = { ast_id = "block_stmt", {ast_id = "break_stmt"} }
    local res = ut:succeeds(self.defs.fundef_l, n"a", {}, body)
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.kind, "local")
    ut:equals(res.name.name, "a")
    ut:equals(res.selfname, nil)
    ut:equals(#res.param, 0)
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M:funparm(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local ell = { ast_id = "literal", value = "..." }
    local res = ut:succeeds(self.defs.funparm, ell)
    ut:equals(res[1].value, "...")
    res = ut:succeeds(self.defs.funparm, {n("a")}, ell)
    ut:equals(res[1].name, "a")
    ut:equals(res[2].value, "...")
    res = ut:succeeds(self.defs.funparm, {n("a"), n"b",n"c"}, ell)
    ut:equals(res[1].name, "a")
    ut:equals(res[2].name, "b")
    ut:equals(res[3].name, "c")
    ut:equals(res[4].value, "...")
    res = ut:succeeds(self.defs.funparm, {n("a"), n"b",n"c"})
    ut:equals(res[1].name, "a")
    ut:equals(res[2].name, "b")
    ut:equals(res[3].name, "c")
end

function M:funname(ut)
    local n = function (a) return { ast_id = "name", name = a } end
    local name, selfname = ut:succeeds(self.defs.funname, {n("a"), n"b", n"c"}, n("selfname"))
    ut:equals(name.kind, ".")
    ut:equals(name.rhs.name, "c")
    ut:equals(name.lhs.kind, ".")
    ut:equals(name.lhs.rhs.name, "b")
    ut:equals(name.lhs.lhs.name, "a")
    ut:equals(selfname.name, "selfname")
    name, selfname = ut:succeeds(self.defs.funname, {n("a")})
    ut:equals(name.name, "a")
    ut:equals(selfname, nil)
end

function M:tbldef(ut)
    local one,two = {ast_id = "tblfld", value = {ast_id = "literal", value = "1" }},
                    {ast_id = "tblfld", value = { ast_id = "literal", value = "2" }}
    local res = ut:succeeds(self.defs.tabledef, "dummy", one, two, one, two, one)
    ut:equals(res.ast_id, "tbldef")
    ut:equals(res[1], one)
    ut:equals(res[2], two)
    ut:equals(res[3], one)
    ut:equals(res[4], two)
    ut:equals(res[5], one)
    res = ut:succeeds(self.defs.tabledef, "dummy")
    ut:equals(res.ast_id, "tbldef")
    ut:equals(res[1], nil)
    ut:equals(res[2], nil)
    ut:equals(res[3], nil)
    ut:equals(res[4], nil)
    ut:equals(res[5], nil)
    res = ut:succeeds(self.defs.tabledef, "dummy", two,one)
    ut:equals(res.ast_id, "tbldef")
    ut:equals(res[1], two)
    ut:equals(res[2], one)
    ut:equals(res[3], nil)
    ut:equals(res[4], nil)
    ut:equals(res[5], nil)
end

function M:field(ut)
    local res = ut:succeeds(self.defs.field, "dummy", "op", "key", "val")
    ut:equals(res.ast_id, "tblfld")
    ut:equals(res.kind, "expr")
    ut:equals(res.key, "key")
    ut:equals(res.value, "val")
    res = ut:succeeds(self.defs.field, "dummy", "op", "key")
    ut:equals(res.ast_id, "tblfld")
    ut:equals(res.kind, "name")
    ut:equals(res.key, "op")
    ut:equals(res.value, "key")
    res = ut:succeeds(self.defs.field, "dummy", "op")
    ut:equals(res.ast_id, "tblfld")
    ut:equals(res.kind, nil)
    ut:equals(res.key, nil)
    ut:equals(res.value, "op")
    res = ut:succeeds(self.defs.field, nil, "op", "key", "val")
    ut:equals(res.ast_id, "tblfld")
    ut:equals(res.kind, "expr")
    ut:equals(res.key, "key")
    ut:equals(res.value, "val")
    res = ut:succeeds(self.defs.field, nil, "op", "key")
    ut:equals(res.ast_id, "tblfld")
    ut:equals(res.kind, "name")
    ut:equals(res.key, "op")
    ut:equals(res.value, "key")
    res = ut:succeeds(self.defs.field, nil, "op")
    ut:equals(res.ast_id, "tblfld")
    ut:equals(res.kind, nil)
    ut:equals(res.key, nil)
    ut:equals(res.value, "op")
end

function M:name(ut)
    local result = ut:succeeds(self.defs.name,"hello")
    ut:equals(result.ast_id, "name")
    ut:equals(result.name, "hello")
end

function M:literal( ut )
    local result = ut:succeeds(self.defs.literal,[==[1]==])
    ut:equals(result.ast_id, 'literal')
    ut:equals(result.value, [==[1]==])
    result = ut:succeeds(self.defs.literal,[==["fef"]==])
    ut:equals(result.ast_id, 'literal')
    ut:equals(result.value, [==["fef"]==])
    result = ut:succeeds(self.defs.literal,[==['fef']==])
    ut:equals(result.ast_id, 'literal')
    ut:equals(result.value, [==['fef']==])
    result = ut:succeeds(self.defs.literal,[==[[[fef]]]==])
    ut:equals(result.ast_id, 'literal')
    ut:equals(result.value, [==[[[fef]]]==])
    result = ut:succeeds(self.defs.literal,[==[[=[fef]=]]==])
    ut:equals(result.ast_id, 'literal')
    ut:equals(result.value, [==[[=[fef]=]]==])
    result = ut:succeeds(self.defs.literal,[==[...]==])
    ut:equals(result.ast_id, 'literal')
    ut:equals(result.value, [==[...]==])
end

return M
