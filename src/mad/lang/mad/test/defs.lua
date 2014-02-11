local M = {}

function M:setUp()
    self.defs = require"mad.lang.mad.defs".defs
end

function M:tearDown()
    self.defs = nil
end

function M:error( ut )
    ut:fails(self.defs.error,[[a = 1]], 0)
end



function M:lambda(ut)
    local res = ut:succeeds(self.defs.lambda, {}, {}, {ast_id = "literal", value = "1" })
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.kind, "lambda")
    ut:equals(res.block[1][1].value, "1")
    res = ut:succeeds(self.defs.lambda, {}, {{ast_id = "literal", value = "1" },{ast_id = "literal", value = "2" }})
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.kind, "lambda")
    ut:equals(res.block[1][1].value, "1")
    ut:equals(res.block[1][2].value, "2")
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
