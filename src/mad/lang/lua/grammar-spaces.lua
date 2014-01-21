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
                      ';' / label / break / goto name / do_block / fundef
                    / varlist s'=' explist / funstmt
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

    exp         <- orexp
    orexp       <- andexp    ( or      andexp  )*
    andexp      <- boolexp   ( and     boolexp )*
    boolexp     <- catexp    ( boolop  catexp  )*
    catexp      <- sumexp    ( catop   sumexp  )*
    sumexp      <- prodexp   ( sumop   prodexp )*
    prodexp     <- unexp     ( prodop  unexp   )*
    unexp       <-             unop*   powexp
    powexp      <- valexp    ( powop   valexp  )*
    
    valexp      <- literal / tabledef / fundef_a / varexp
    varexp      <- (name   / grpexp) (tableidx / funcall)*
    grpexp      <- s'(' exp s')'
    
    explist     <- exp (s',' exp)*

-- variable definitions (only on lhs of '=')

    vardef      <- (name / grpexp varsfx) varsfx*
    varsfx      <- funcall* tableidx
    varlist     <- vardef (s',' vardef)*

-- function definitions & call

    fundef      <- fundef_n / fundef_l
    fundef_a    <- function funbody             -- anonymous
    fundef_n    <- function funname funbody     -- named
    fundef_l    <- local function name funbody  -- local named

    funname     <- name (s'.' name)* (s':' name)?
    funbody     <- s'(' funparm? s')' block end
    funparm     <- namelist (s',' ellipsis)? / ellipsis

    funstmt     <- (name / grpexp) varsfx* funcall+

    funcall     <- ( s':' name )? funargs
    funargs     <- s'(' explist? s')' / tabledef / string

-- table definitions & access

    tabledef    <- s'{' fieldlist? s'}'
    fieldlist   <- field (fieldsep field)* fieldsep?
    field       <- s'[' exp s']' s'=' exp / name s'=' exp / exp
    fieldsep    <- s',' / s';'
    
    tableidx    <- s'[' exp s']' / s'.' name

-- operators

    boolop      <- s( '<=' / '<' / '>=' / '>' / '==' / '~=' )
    catop       <- s  '..'
    sumop       <- s( '+' / '-' )
    prodop      <- s( '*' / '/' / '%' )
    unop        <- s( not / '#' / '-' )
    powop       <- s  '^'
    
-- lexems

    literal     <- nil / false / true / number / string / ellipsis
    name        <- s !keyword ident
    namelist    <- name (s',' name)*
    string      <- s( sstring / lstring )
    number      <- s( hexnum / decnum )
    ellipsis    <- s'...'

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

function M.test:block(ut)
    local grammar = "rule <- block? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ";;;;;")
    ut:succeeds(parser.match, parser, "return 1")
    ut:succeeds(parser.match, parser, "    ; ; ;;return 1")
    ut:fails(parser.match, parser, ";;return 1;;;;")
end

function M.test:stmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
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

function M.test:emptystmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ";")
end

function M.test:label(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "::fe::")
end

function M.test:breakstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "break")
end

function M.test:gotostmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "goto few")
end

function M.test:dostmt(ut)
    local grammar = "rule <- do_block? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "do ; end")
end

function M.test:fundef(ut)
    local grammar = "rule <- fundef? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "function a () return end")
    ut:succeeds(parser.match, parser, "local function a () return end")
    ut:succeeds(parser.match, parser, "function a.a:a () return end")
    ut:fails(parser.match, parser, "function a:a.a () return end")
end

function M.test:varlistassign(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a, b = 1, 2")
    ut:succeeds(parser.match, parser, "a = 1, 2")
    ut:succeeds(parser.match, parser, "a, b, a, a, a = 1")
end

function M.test:whilestmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "while true do ; end")
end

function M.test:repeatstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "repeat ; until false")
end

function M.test:ifstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "if false then ; elseif false then elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then elseif false then ; end")
    ut:succeeds(parser.match, parser, "if false then ; ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ; elseif false then elseif false then ; else ; end")
    ut:succeeds(parser.match, parser, "if false then ;end")
end

function M.test:forstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "for fea = 1, 1, 1 do ; end")
    ut:succeeds(parser.match, parser, "for fea = 1, 1 do ; end")
end

function M.test:forinstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "for few in eqw do ; end")
    ut:succeeds(parser.match, parser, "for few,feww in eqw() do ; end")
end


function M.test:varexp(ut)
    local grammar = "rule <- varexp? s (!./''=>error)\n" .. M.grammar
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

function M.test:funstmt(ut)
    local grammar = "rule <- funstmt? s (!./''=>error)\n" .. M.grammar
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

function M.test:vardef(ut)
    local grammar = "rule <- vardef? s (!./''=>error)\n" .. M.grammar
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

function M.test:grpexp(ut)
    local grammar = "rule <- grpexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "(1)")
    ut:succeeds(parser.match, parser, "(few)")
    ut:fails(parser.match, parser, "h(a)")
end

function M.test:funcall(ut)
    local grammar = "rule <- funcall? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, ":a()")
    ut:succeeds(parser.match, parser, "()")
    ut:succeeds(parser.match, parser, "(a,2,g)")
    ut:succeeds(parser.match, parser, "''")
    ut:fails(parser.match, parser, "h(a)")
end

function M.test:funargs(ut)
    local grammar = "rule <- funargs? s (!./''=>error)\n" .. M.grammar
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

function M.test:funparm(ut)
    local grammar = "rule <- funparm? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "...")
    ut:succeeds(parser.match, parser, "a")
    ut:succeeds(parser.match, parser, "a,b")
    ut:succeeds(parser.match, parser, "a,...")
end

function M.test:tabledef(ut)
    local grammar = "rule <- tabledef? s (!./''=>error)\n" .. M.grammar
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

function M.test:exp(ut)
    local grammar = "rule <- exp? s (!./''=>error)\n" .. M.grammar
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

function M.test:orexp(ut)
    local grammar = "rule <- orexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1 or 1")
    ut:succeeds(parser.match, parser, "true or true or false and true or true")
end

function M.test:andexp(ut)
    local grammar = "rule <- andexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "false and true")
    ut:succeeds(parser.match, parser, "1+1 and true")
    ut:fails(parser.match, parser, "true or false")
end

function M.test:boolexp(ut)
    local grammar = "rule <- boolexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1 < 2")
    ut:succeeds(parser.match, parser, "2 <= 2")
    ut:succeeds(parser.match, parser, "2 > 2")
    ut:succeeds(parser.match, parser, "2>=2")
    ut:succeeds(parser.match, parser, "2 == 2")
    ut:succeeds(parser.match, parser, "2~=1")
end

function M.test:catexp(ut)
    local grammar = "rule <- catexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "'fl'..'fefe'")
    ut:succeeds(parser.match, parser, "a..'222'")
end

function M.test:sumexp(ut)
    local grammar = "rule <- sumexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1+1")
    ut:succeeds(parser.match, parser, "1-1")
    ut:succeeds(parser.match, parser, "a-4")
    ut:succeeds(parser.match, parser, "5-524+f-123-fewf")
end

function M.test:prodexp(ut)
    local grammar = "rule <- prodexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "a*2")
    ut:succeeds(parser.match, parser, "a/2")
    ut:succeeds(parser.match, parser, "a*2*gb/ge")
end

function M.test:unexp(ut)
    local grammar = "rule <- unexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "-1")
    ut:succeeds(parser.match, parser, "#a")
    ut:succeeds(parser.match, parser, "not true")
    ut:succeeds(parser.match, parser, "- - 2")
    ut:succeeds(parser.match, parser, "- - #######- - - - -2")
end

function M.test:powexp(ut)
    local grammar = "rule <- powexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "1^2")
    ut:succeeds(parser.match, parser, "1^2^2^2")
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
