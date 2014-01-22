local M = {}

function M:setUp()
    self.grammar = require"mad.lang.lua.grammar-spaces".grammar
    self.compile = require"lib.lpeg.re".compile
    self.defs = require"mad.lang.lua.defs".defs
end

function M:tearDown()
    self.compile = nil
    self.defs = nil
end

function M:block(ut)
    local grammar = "rule <- block? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ";;;;;")
    ut:succeeds(parser.match, parser, "return 1")
    ut:succeeds(parser.match, parser, "    ; ; ;;return 1")
    ut:fails(parser.match, parser, ";;return 1;;;;")
end

function M:stmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ";")
    ut:succeeds(parser.match, parser, "::fe::")
    ut:succeeds(parser.match, parser, "break")
    ut:succeeds(parser.match, parser, "goto few")
    ut:succeeds(parser.match, parser, "do ; end")
    ut:succeeds(parser.match, parser, "function a () return end")
    ut:succeeds(parser.match, parser, "a, b = 1, 2")
    ut:succeeds(parser.match, parser, "while true do ; end")
    ut:succeeds(parser.match, parser, "repeat ; until false")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "for fea = 1, 1, 1 do ; end")
    ut:succeeds(parser.match, parser, "for few in eqw do ; end")
end

function M:emptystmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ";")
end

function M:label(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "::fe::")
end

function M:breakstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "break")
end

function M:gotostmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "goto few")
end

function M:dostmt(ut)
    local grammar = "rule <- do_block? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "do ; end")
end

function M:fundef(ut)
    local grammar = "rule <- fundef? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function a () return end")
    ut:succeeds(parser.match, parser, "local function a () return end")
    ut:succeeds(parser.match, parser, "function a.a:a () return end")
    ut:fails(parser.match, parser, "function a:a.a () return end")
end

function M:varlistassign(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a, b = 1, 2")
    ut:succeeds(parser.match, parser, "a = 1, 2")
    ut:succeeds(parser.match, parser, "a, b, a, a, a = 1")
end

function M:whilestmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "while true do ; end")
end

function M:repeatstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "repeat ; until false")
end

function M:ifstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "if false then ; elseif false then elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then elseif false then ; end")
    ut:succeeds(parser.match, parser, "if false then ; ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ;end")
end

function M:forstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "for fea = 1, 1, 1 do ; end")
    ut:succeeds(parser.match, parser, "for fea = 1, 1 do ; end")
end

function M:forinstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "for few in eqw do ; end")
    ut:succeeds(parser.match, parser, "for few,feww in eqw() do ; end")
end


function M:varexp(ut)
    local grammar = "rule <- varexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a()")
    ut:succeeds(parser.match, parser, "a[1]()")
    ut:succeeds(parser.match, parser, "a[a]()")
    ut:succeeds(parser.match, parser, "a.a()")
    ut:succeeds(parser.match, parser, "a['a']()")
    ut:succeeds(parser.match, parser, "a.a:a()")
    ut:succeeds(parser.match, parser, "a[1][1]()")
    ut:succeeds(parser.match, parser, "a.a[1].a[1]()")
    ut:succeeds(parser.match, parser, "a().a()")
    ut:succeeds(parser.match, parser, "a(a)().a()")
    ut:succeeds(parser.match, parser, "a()():a()()")
    ut:succeeds(parser.match, parser, "(a).a()")
    ut:succeeds(parser.match, parser, "(a)()")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a[1]")
    ut:succeeds(parser.match, parser, "a[a]")
    ut:succeeds(parser.match, parser, "a.a")
    ut:succeeds(parser.match, parser, "a['a']")
    ut:succeeds(parser.match, parser, "a.a.a")
    ut:succeeds(parser.match, parser, "a[1][1]")
    ut:succeeds(parser.match, parser, "a.a[1].a[1]")
    ut:succeeds(parser.match, parser, "a().a")
    ut:succeeds(parser.match, parser, "a(a)().a")
    ut:succeeds(parser.match, parser, "(a).a")
end

function M:funstmt(ut)
    local grammar = "rule <- funstmt? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a()")
    ut:succeeds(parser.match, parser, "a[1]()")
    ut:succeeds(parser.match, parser, "a[a]()")
    ut:succeeds(parser.match, parser, "a.a()")
    ut:succeeds(parser.match, parser, "a['a']()")
    ut:succeeds(parser.match, parser, "a.a:a()")
    ut:succeeds(parser.match, parser, "a[1][1]()")
    ut:succeeds(parser.match, parser, "a.a[1].a[1]()")
    ut:succeeds(parser.match, parser, "a().a()")
    ut:succeeds(parser.match, parser, "a(a)():a()")
    ut:succeeds(parser.match, parser, "a()().a()()")
    ut:succeeds(parser.match, parser, "(a).a()")
    ut:succeeds(parser.match, parser, "(a)()")
    ut:fails(parser.match, parser, "a()().a")
    ut:fails(parser.match, parser, "a.a")
    ut:fails(parser.match, parser, "(a)")
end

function M:vardef(ut)
    local grammar = "rule <- vardef? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a[1]")
    ut:succeeds(parser.match, parser, "a[a]")
    ut:succeeds(parser.match, parser, "a.a")
    ut:succeeds(parser.match, parser, "a['a']")
    ut:succeeds(parser.match, parser, "a.a.a")
    ut:succeeds(parser.match, parser, "a[1][1]")
    ut:succeeds(parser.match, parser, "a.a[1].a[1]")
    ut:succeeds(parser.match, parser, "a().a")
    ut:succeeds(parser.match, parser, "a(a)().a")
    ut:fails(parser.match, parser, "a()().a()")
    ut:succeeds(parser.match, parser, "(a).a")
    ut:fails(parser.match, parser, "(a)")
end

function M:grpexp(ut)
    local grammar = "rule <- grpexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "(1)")
    ut:succeeds(parser.match, parser, "(few)")
    ut:fails(parser.match, parser, "h(a)")
end

function M:funcall(ut)
    local grammar = "rule <- funcall? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ":a()")
    ut:succeeds(parser.match, parser, "()")
    ut:succeeds(parser.match, parser, "(a,2,g)")
    ut:succeeds(parser.match, parser, "''")
    ut:fails(parser.match, parser, "h(a)")
end

function M:funargs(ut)
    local grammar = "rule <- funargs? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "()")
    ut:succeeds(parser.match, parser, "'fe'")
    ut:succeeds(parser.match, parser, "{}")
    ut:succeeds(parser.match, parser, "(1)")
    ut:succeeds(parser.match, parser, "(1,2,'joi',few)")
end

function M:fundef(ut)
    local grammar = "rule <- fundef? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function a () return 1 end")
    ut:succeeds(parser.match, parser, "function a.a () return 1 end")
    ut:succeeds(parser.match, parser, "local function a () return 1 end")
    ut:fails(parser.match, parser, "local function () return 1 end")
    ut:fails(parser.match, parser, "local function a.a () return 1 end")
end

function M:fundef_a(ut)
    local grammar = "rule <- fundef_a? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function() return 1 end")
end

function M:fundef_n(ut)
    local grammar = "rule <- fundef_n? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function a () return 1 end")
    ut:succeeds(parser.match, parser, "function a.a () return 1 end")
    ut:fails(parser.match, parser, "local function a () return 1 end")
end

function M:fundef_l(ut)
    local grammar = "rule <- fundef_l? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "local function a () return 1 end")
    ut:fails(parser.match, parser, "local function () return 1 end")
    ut:fails(parser.match, parser, "local function a.a () return 1 end")
end

function M:funname(ut)
    local grammar = "rule <- funname? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a.a.a")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a:a")
    ut:fails(parser.match, parser, "a[a]")
end

function M:funbody(ut)
    local grammar = "rule <- funbody? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "(...) end")
    ut:succeeds(parser.match, parser, "() return 1 end")
end

function M:funparm(ut)
    local grammar = "rule <- funparm? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "...")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a,b")
    ut:succeeds(parser.match, parser, "a,...")
end

function M:tabledef(ut)
    local grammar = "rule <- tabledef? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "{}")
    ut:succeeds(parser.match, parser, "{[1] = 12, [1] = 12; [1] = 12}")
end

function M:fieldlist(ut)
    local grammar = "rule <- fieldlist? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "[1] = 12, [1] = 12; [1] = 12")
    ut:succeeds(parser.match, parser, "[1] = 12;")
    ut:succeeds(parser.match, parser, "[1] = 12;[1] = 12;  [1] = 12;")
end

function M:field(ut)
    local grammar = "rule <- field? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "[1] = 12")
    ut:succeeds(parser.match, parser, "[a] = 12")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "1")
    ut:succeeds(parser.match, parser, "a = 12")
end

function M:exp(ut)
    local grammar = "rule <- exp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1 or 1")
    ut:succeeds(parser.match, parser, "true or true or false and true or true")
    ut:succeeds(parser.match, parser, "name or 2")
    ut:succeeds(parser.match, parser, "name and 2")
    ut:succeeds(parser.match, parser, "name == 2")
    ut:succeeds(parser.match, parser, "name..2")
    ut:succeeds(parser.match, parser, "name+2")
    ut:succeeds(parser.match, parser, "name*2")
    ut:succeeds(parser.match, parser, "#name")
    ut:succeeds(parser.match, parser, "name^2")
end

function M:orexp(ut)
    local grammar = "rule <- orexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1 or 1")
    ut:succeeds(parser.match, parser, "true or true or false and true or true")
end

function M:andexp(ut)
    local grammar = "rule <- andexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "false and true")
    ut:succeeds(parser.match, parser, "1+1 and true")
    ut:fails(parser.match, parser, "true or false")
end

function M:boolexp(ut)
    local grammar = "rule <- boolexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1 < 2")
    ut:succeeds(parser.match, parser, "2 <= 2")
    ut:succeeds(parser.match, parser, "2 > 2")
    ut:succeeds(parser.match, parser, "2>=2")
    ut:succeeds(parser.match, parser, "2 == 2")
    ut:succeeds(parser.match, parser, "2~=1")
end

function M:catexp(ut)
    local grammar = "rule <- catexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "'fl'..'fefe'")
    ut:succeeds(parser.match, parser, "a..'222'")
end

function M:sumexp(ut)
    local grammar = "rule <- sumexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1+1")
    ut:succeeds(parser.match, parser, "1-1")
    ut:succeeds(parser.match, parser, "a-4")
    ut:succeeds(parser.match, parser, "5-524+f-123-fewf")
end

function M:prodexp(ut)
    local grammar = "rule <- prodexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a*2")
    ut:succeeds(parser.match, parser, "a/2")
    ut:succeeds(parser.match, parser, "a*2*gb/ge")
end

function M:unexp(ut)
    local grammar = "rule <- unexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "-1")
    ut:succeeds(parser.match, parser, "#a")
    ut:succeeds(parser.match, parser, "not true")
    ut:succeeds(parser.match, parser, "- - 2")
    ut:succeeds(parser.match, parser, "- - #######- - - - -2")
end

function M:powexp(ut)
    local grammar = "rule <- powexp? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1^2")
    ut:succeeds(parser.match, parser, "1^2^2^2")
end


function M:comment(ut)
    local grammar = "rule <- number? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "--[[fewfw]]3")
    ut:succeeds(parser.match, parser, "3.0--fewfwe")
    ut:succeeds(parser.match, parser, "3.1416--[=[fewfw]=]")
end

function M:number(ut)
    local grammar = "rule <- number? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    --Tests taken from 5.2 reference manual
    ut:succeeds(parser.match, parser, "3")
    ut:succeeds(parser.match, parser, "3.0")
    ut:succeeds(parser.match, parser, "3.1416")
    ut:succeeds(parser.match, parser, "314.16e-2")
    ut:succeeds(parser.match, parser, "0.31416E1")
    ut:succeeds(parser.match, parser, "0xff")
    ut:succeeds(parser.match, parser, "0x0.1E")
    ut:succeeds(parser.match, parser, "0xA23p-4")
    ut:succeeds(parser.match, parser, "0X1.921FB54442D18P+1")
    ut:fails(parser.match, parser, "3a")
    ut:fails(parser.match, parser, "3a.0a")
    ut:fails(parser.match, parser, "3a.14a16")
    ut:fails(parser.match, parser, "31a4.1a6e-2a")
    ut:fails(parser.match, parser, "0.3a1416E1")
    ut:fails(parser.match, parser, "0xfnf")
    ut:fails(parser.match, parser, "0x0n.1nE")
    ut:fails(parser.match, parser, "0xAn23p-n4")
    ut:fails(parser.match, parser, "0X1.92n1FB54442D18P+1")
end

function M:string(ut)
    local grammar = "rule <- string? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, [=====["gvrewgr"]=====])
    ut:succeeds(parser.match, parser, [=====['few']=====])
    ut:succeeds(parser.match, parser, [=====[[[fe]]]=====])
    ut:succeeds(parser.match, parser, [=====[[=[dfew]=]]=====])
    ut:succeeds(parser.match, parser, [=====["'[['"]=====])
    ut:fails(parser.match, parser,    [=====["hiohjoi']=====])
    ut:succeeds(parser.match, parser, [=====[[[
                                                fee]]]=====])
    ut:succeeds(parser.match, parser, [=====["\"\123\n\t\s\r"]=====])
end

function M:name(ut)
    local grammar = "rule <- name? s (!./''=>error)\n" .. self.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "few")
    ut:succeeds(parser.match, parser, "few_few")
    ut:succeeds(parser.match, parser, "few21_few21")
    ut:succeeds(parser.match, parser, "_few")
    ut:succeeds(parser.match, parser, "functions")
    ut:fails(parser.match, parser, "2few")
    ut:fails(parser.match, parser, "few-few")
    ut:fails(parser.match, parser, "few/few")
    ut:fails(parser.match, parser, "?")
    ut:fails(parser.match, parser, "3124")
    ut:fails(parser.match, parser, "function")
    ut:fails(parser.match, parser, "goto")
end

return M
