local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  grammar

SYNOPSIS
  local grammar = require"lang.parser.lua.grammar".grammar

DESCRIPTION
  Returns the regex-based grammar of Lua.

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- grammar ---------------------------------------------------------------------

M.grammar = [=[
-- top level rules

    chunk       <- block s(!./''=>error)
    block       <- stmt* retstmt?

-- statements

    stmt        <- s(
                      ';' / label / break / goto name / do_block / fundef / funcall
                    / varlist s'=' explist
                    / local namelist (s'=' explist)?
                    / while exp do_block
                    / repeat block until exp
                    / if exp then block (elseif exp then block)* (else block)? end
                    / for name s'=' exp s',' exp (s',' exp)? do_block
                    / for namelist in explist do_block
                    )

    do_block    <- do block end

-- extra stmts

    label       <- s'::' name s'::'
    retstmt     <- return explist? s';'?

-- expressions

--*    exp         <- nil / false / true / number / string / s'...' / 
--                   fundef_a / prefixexp / tablector /
--                   exp binop exp / unop exp

    exp         <- expval exp_r / unop exp exp_r
    exp_r       <- ( binop exp exp_r )?
    expval      <- nil / false / true / number / string / s'...' / 
                   fundef_a / prefixexp / tablector

    prefixexp   <- funcall / var / paranexp
--* prefixexp   <- var / funcall / s'(' exp s')'
--    prefixexp   <- name prefixexp_r / s'(' exp s')' prefixexp_r

    explist     <- exp (s',' exp)*
    
    paranexp    <- s'(' exp s')'
    
--    suffixexp   <- index / call
--    prefixexp_r <- s( suffixexp prefixexp_r )?

-- variables

    var         <- varprefix varsuffix*
    varprefix   <- name / paranexp varsuffix
    varsuffix   <- call* index
    index       <- s'[' exp s']' / s'.' name

    varlist     <- var (s',' var)*
    
--* var         <- name / prefixexp s'[' exp s']' / prefixexp s'.' name
--    var         <- prefixexp index / name --TODO index will always be eaten by suffixexp in prefixexp. pref index/name

-- function invocations

    funcall     <- callprefix call+
    callprefix  <- var / paranexp
    call        <- ( s':' name )? args
    args        <- s'(' explist? s')' / tablector / string

--* funcall     <- prefixexp args / prefixexp s':' name args
--    funcall     <- prefixexp call --TODO remove call? Won't it always be eaten by suffixexp? pref call

-- function definitions

    fundef      <- fundef_n / fundef_l
    fundef_a    <- function funbody             -- anonymous
    fundef_n    <- function funname funbody     -- named
    fundef_l    <- local function name funbody  -- local named

    funname     <- name (s'.' name)* (s':' name)?
    funbody     <- s'(' parlist? s')' block end
    parlist     <- namelist (s',' s'...')? / s'...'

-- table definitions

    tablector   <- s'{' fieldlist? s'}'
    fieldlist   <- field (fieldsep field)* fieldsep?
    field       <- s'[' exp s']' s'=' exp / name s'=' exp / exp
    fieldsep    <- s',' / s';'

-- operators

    binop       <- s( '+' / '-' / '*' / '/' / '^' / '%' / '..' / '<=' / '<' / '>=' / '>' / '==' / '~=' / and / or )
    unop        <- s( '-' / not / '#' )

-- lexems

    name        <- s !keyword ident
    namelist    <- name (s',' name)*
    string      <- s( sstring / lstring )
    number      <- s( hexnum / decnum )

-- basic lexems

    sstring     <- {:qt: ['"] :} ssclose
    ssclose     <- =qt / '\' =qt ssclose / ch ssclose

    lstring     <- '[' {:eq: '='* :} '[' lsclose
    lsclose     <- ']' =eq ']' / any lsclose

    decnum      <-         num ('.' num)? ([eE] sign? num)?
    hexnum      <- '0'[xX] hex ('.' hex)? ([pP] sign? hex)?

    ident       <- [A-Za-z_][A-Za-z0-9_]*
    e           <- ![A-Za-z0-9_]
    hex         <- [0-9A-Fa-f]+
    num         <- [0-9]+
    sign        <- [-+]
    any         <- ch / nl
    s           <- (ws / nl / cmt)*

-- keywords

    keyword     <- and / break / do / else / elseif / end / false / for /
                   function / goto / if / in / local / nil / not /
                   or / repeat / return / then / true / until / while

    and         <- s'and'      e
    break       <- s'break'    e
    do          <- s'do'       e
    else        <- s'else'     e
    elseif      <- s'elseif'   e
    end         <- s'end'      e
    false       <- s'false'    e 
    for         <- s'for'      e
    function    <- s'function' e
    goto        <- s'goto'     e
    if          <- s'if'       e
    in          <- s'in'       e
    local       <- s'local'    e
    nil         <- s'nil'      e
    not         <- s'not'      e 
    or          <- s'or'       e
    repeat      <- s'repeat'   e
    return      <- s'return'   e
    then        <- s'then'     e
    true        <- s'true'     e
    until       <- s'until'    e
    while       <- s'while'    e
    
-- comments

    cmt    <- '--' ( lstring / ch* (nl/!.) )

]=]
-- escape characters, must be outside long strings
.. "ws <- [ \t\r]"
.. "ch <- [^\n]"
.. "nl <- [\n]"

-- test -----------------------------------------------------------------------

function M.test:setUp()
    self.compile = require"lib.lpeg.re".compile
    self.defs = require"mad.lang.lua.defs".defs
end

function M.test:tearDown()
    self.compile = nil
    self.defs = nil
end

function M.test:prefixexp(ut)
    local grammar = "rule <- prefixexp? s (!./''=>error)\n" .. M.grammar
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

function M.test:funcall(ut)
    local grammar = "rule <- funcall? s (!./''=>error)\n" .. M.grammar
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

function M.test:var(ut)
    local grammar = "rule <- var? s (!./''=>error)\n" .. M.grammar
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

function M.test:paranexp(ut)
    local grammar = "rule <- paranexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "(1)")
    ut:succeeds(parser.match, parser, "(few)")
    ut:fails(parser.match, parser, "h(a)")
end

function M.test:call(ut)
    local grammar = "rule <- call? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ":a()")
    ut:succeeds(parser.match, parser, "()")
    ut:succeeds(parser.match, parser, "(a,2,g)")
    ut:succeeds(parser.match, parser, "''")
    ut:fails(parser.match, parser, "h(a)")
end

function M.test:args(ut)
    local grammar = "rule <- args? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "()")
    ut:succeeds(parser.match, parser, "'fe'")
    ut:succeeds(parser.match, parser, "{}")
    ut:succeeds(parser.match, parser, "(1)")
    ut:succeeds(parser.match, parser, "(1,2,'joi',few)")
end

function M.test:fundef(ut)
    local grammar = "rule <- fundef? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function a () return 1 end")
    ut:succeeds(parser.match, parser, "function a.a () return 1 end")
    ut:succeeds(parser.match, parser, "local function a () return 1 end")
    ut:fails(parser.match, parser, "local function () return 1 end")
    ut:fails(parser.match, parser, "local function a.a () return 1 end")
end

function M.test:fundef_a(ut)
    local grammar = "rule <- fundef_a? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function() return 1 end")
end

function M.test:fundef_n(ut)
    local grammar = "rule <- fundef_n? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function a () return 1 end")
    ut:succeeds(parser.match, parser, "function a.a () return 1 end")
    ut:fails(parser.match, parser, "local function a () return 1 end")
end

function M.test:fundef_l(ut)
    local grammar = "rule <- fundef_l? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "local function a () return 1 end")
    ut:fails(parser.match, parser, "local function () return 1 end")
    ut:fails(parser.match, parser, "local function a.a () return 1 end")
end

function M.test:funname(ut)
    local grammar = "rule <- funname? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a.a.a")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a:a")
    ut:fails(parser.match, parser, "a[a]")
end

function M.test:funbody(ut)
    local grammar = "rule <- funbody? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "(...) end")
    ut:succeeds(parser.match, parser, "() return 1 end")
end

function M.test:parlist(ut)
    local grammar = "rule <- parlist? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "...")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a,b")
    ut:succeeds(parser.match, parser, "a,...")
end

function M.test:tablector(ut)
    local grammar = "rule <- tablector? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "{}")
    ut:succeeds(parser.match, parser, "{[1] = 12, [1] = 12; [1] = 12}")
end

function M.test:fieldlist(ut)
    local grammar = "rule <- fieldlist? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "[1] = 12, [1] = 12; [1] = 12")
    ut:succeeds(parser.match, parser, "[1] = 12;")
    ut:succeeds(parser.match, parser, "[1] = 12;[1] = 12;  [1] = 12;")
end

function M.test:field(ut)
    local grammar = "rule <- field? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "[1] = 12")
    ut:succeeds(parser.match, parser, "[a] = 12")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "1")
    ut:succeeds(parser.match, parser, "a = 12")
end

function M.test:comment(ut)
    local grammar = "rule <- number? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "--[[fewfw]]3")
    ut:succeeds(parser.match, parser, "3.0--fewfwe")
    ut:succeeds(parser.match, parser, "3.1416--[=[fewfw]=]")
end

function M.test:number(ut)
    local grammar = "rule <- number? s (!./''=>error)\n" .. M.grammar
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

function M.test:string(ut)
    local grammar = "rule <- string? s (!./''=>error)\n" .. M.grammar
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

function M.test:name(ut)
    local grammar = "rule <- name? s (!./''=>error)\n" .. M.grammar
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



-- end ------------------------------------------------------------------------

return M
