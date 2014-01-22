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

    chunk       <- ((''=>setup) block s(!./''=>error))                          -> chunk
    block       <- {stmt* retstmt?}                                             -> block

-- statements

    stmt        <- s(
                      ';' / label / break                                       -> breakstmt 
                    / goto name                                                 -> gotostmt
                    / do_block                                                  -> dostmt 
                    / fundef
                    / ({|varlist|} s'=' {|explist|})                            -> assign 
                    / funstmt
                    / (local {|namelist|} (s'=' {|explist|})?)                  -> locassign
                    / (while exp do_block)                                      -> whilestmt
                    / (repeat block until exp)                                  -> repeatstmt
                    / {if exp then block 
                        (elseif exp then block)*
                        (else block)? end}                                      -> ifstmt
                    / (for name s'=' exp s',' exp (s',' exp)? do_block)         -> forstmt
                    / (for {|namelist|} in {|explist|} do_block)                -> forinstmt
                    )

    do_block    <- do block end

-- extra stmts

    label       <- {s'::' name s'::'}                                           -> label
    retstmt     <- {return explist? s';'?}                                      -> retstmt

-- expressions

    exp         <- { orexp }                                                    -> exp
    orexp       <- { andexp   ( or      andexp  )* }                            -> orexp
    andexp      <- { logexp   ( and     logexp  )* }                            -> andexp
    logexp      <- { catexp   ( logop   catexp  )* }                            -> logexp
    catexp      <- { sumexp   ( catop   sumexp  )* }                            -> catexp
    sumexp      <- { prodexp  ( sumop   prodexp )* }                            -> sumexp
    prodexp     <- { unexp    ( prodop  unexp   )* }                            -> prodexp
    unexp       <- {          ( unop*   powexp  )  }                            -> unexp
    powexp      <- { valexp   ( powop   valexp  )* }                            -> powexp
    
    valexp      <- literal / tabledef / fundef_a / varexp
    varexp      <- ((name   / grpexp) (tableidx / funcall)*)                    -> varexp
    grpexp      <- (s'(' exp s')')                                              -> grpexp
    
    explist     <- exp (s',' exp)*

-- variable definitions (only on lhs of '=')

    vardef      <- ((name / grpexp varsfx) varsfx*)                             -> vardef
    varsfx      <- funcall* tableidx
    varlist     <- vardef (s',' vardef)*

-- function definitions & call

    fundef      <- fundef_n / fundef_l
    fundef_a    <- (function funbody)                                           -> fundef_a -- anonymous
    fundef_n    <- (function funname funbody)                                   -> fundef_n -- named
    fundef_l    <- (local function name funbody)                                -> fundef_l -- local named

    funname     <- ({|name (s'.' name)*|} (s':' name)?)                         -> funname
    funbody     <- (s'(' {|funparm?|} s')' block end)                           -> funbody
    funparm     <- ({|namelist|}(s','s ellipsis->literal)? /s ellipsis->literal)-> funparm

    funstmt     <- ((name / grpexp) varsfx* funcall+)                           -> funstmt

    funcall     <- (( s{':'} name )? funargs)                                   -> funcall
    funargs     <- s'(' explist? s')' / tabledef / (string->literal)

-- table definitions & access

    tabledef    <- (s'{' { fieldlist? } s'}')                                   -> tabledef
    fieldlist   <- field (fieldsep field)* fieldsep?
    field       <- {s{'['} exp s']' s'=' exp / name s'=' exp / exp}             -> field
    fieldsep    <- s',' / s';'
    
    tableidx    <- (s{'['} exp s']' / s{'.'} name)                              -> tableidx

-- operators

    logop       <- s{'<=' / '<' / '>=' / '>' / '==' / '~='}
    catop       <- s{'..'}
    sumop       <- s{'+' / '-'}
    prodop      <- s{'*' / '/' / '%'}
    unop        <- s{not / '#' / '-'}
    powop       <- s{'^'}
    
-- lexems

    literal     <- s{nil / false / true / number / string / ellipsis}           -> literal
    
    name        <- s !keyword {ident}                                           -> name
    namelist    <- name (s',' name)*
    string      <- s(sstring / lstring)
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

    and         <- s{'and'}    e
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
    or          <- s{'or'}     e
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
.. "nl <- [\n] -> newLine"

-- test -----------------------------------------------------------------------

--[[if mad_loadtest then
M.test = require "mad.lang.lua.test.defs"
end]]

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
    local res = ut:succeeds(parser.match, parser, ";;;;;")
    res = ut:succeeds(parser.match, parser, "return 1")
    res = ut:succeeds(parser.match, parser, "    ; ; ;;return 1")
    ut:fails(parser.match, parser, ";;return 1;;;;")
end

function M.test:stmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, ";")
    res = ut:succeeds(parser.match, parser, "::fe::")
    res = ut:succeeds(parser.match, parser, "break")
    res = ut:succeeds(parser.match, parser, "goto few")
    res = ut:succeeds(parser.match, parser, "do ; end")
    res = ut:succeeds(parser.match, parser, "function a () return end")
    res = ut:succeeds(parser.match, parser, "a, b = 1, 2")
    res = ut:succeeds(parser.match, parser, "while true do ; end")
    res = ut:succeeds(parser.match, parser, "repeat ; until false")
    res = ut:succeeds(parser.match, parser, "if false then ; elseif false then ; else ; end")
    res = ut:succeeds(parser.match, parser, "for fea = 1, 1, 1 do ; end")
    res = ut:succeeds(parser.match, parser, "for few in eqw do ; end")
end

function M.test:emptystmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, ";")
end

function M.test:retstmt(ut)
    local grammar = "rule <- retstmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "return 1")
    ut:equals(res[1].value, "1")
    ut:equals(res.ast_id, "ret_stmt")
end

function M.test:label(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "::fe::")
    ut:equals(res.name.name, "fe")
    ut:equals(res.ast_id, "label_stmt")
end

function M.test:breakstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "break")
    ut:equals(res.ast_id, "break_stmt")
end

function M.test:gotostmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "goto few")
    ut:equals(res.name.name, "few")
    ut:equals(res.ast_id, "goto_stmt")
end

function M.test:dostmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "do break end")
    ut:equals(res.ast_id, "do_stmt")
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M.test:fundef(ut)
    local grammar = "rule <- fundef? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "function a () return end")
    res = ut:succeeds(parser.match, parser, "local function a () return end")
    res = ut:succeeds(parser.match, parser, "function a.a:a () return end")
    ut:fails(parser.match, parser, "function a:a.a () return end")
end

function M.test:varlistassign(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "a, b = 1, 2")
    ut:equals(res.ast_id, "assign")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].value, "1")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.rhs[2].value, "2")
    res = ut:succeeds(parser.match, parser, "a = 1, 2")
    ut:equals(res.ast_id, "assign")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].value, "1")
    ut:equals(res.rhs[2].value, "2")
    res = ut:succeeds(parser.match, parser, "a, b, a, a, a = 1")
    ut:equals(res.ast_id, "assign")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].value, "1")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.lhs[3].name, "a")
    ut:equals(res.lhs[4].name, "a")
    ut:equals(res.lhs[5].name, "a")
end

function M.test:localassign(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "local a, b = 1, 2")
    ut:equals(res.kind, "local")
    ut:equals(res.ast_id, "assign")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].value, "1")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.rhs[2].value, "2")
    res = ut:succeeds(parser.match, parser, "local a = 1, 2")
    ut:equals(res.kind, "local")
    ut:equals(res.ast_id, "assign")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].value, "1")
    ut:equals(res.rhs[2].value, "2")
    res = ut:succeeds(parser.match, parser, "local a, b, a, a, a = 1")
    ut:equals(res.kind, "local")
    ut:equals(res.ast_id, "assign")
    ut:equals(res.lhs[1].name, "a")
    ut:equals(res.rhs[1].value, "1")
    ut:equals(res.lhs[2].name, "b")
    ut:equals(res.lhs[3].name, "a")
    ut:equals(res.lhs[4].name, "a")
    ut:equals(res.lhs[5].name, "a")
end

function M.test:whilestmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "while true do break end")
    ut:equals(res.ast_id, "while_stmt")
    ut:equals(res.expr.value, "true")
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M.test:repeatstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "repeat break until false")
    ut:equals(res.ast_id, "repeat_stmt")
    ut:equals(res.expr.value, "false")
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M.test:ifstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "if false then break elseif false then break elseif false then break else break end")
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].value, "false")
    ut:equals(res[2][1].ast_id, "break_stmt")
    ut:equals(res[3].value, "false")
    ut:equals(res[4][1].ast_id, "break_stmt")
    ut:equals(res[5].value, "false")
    ut:equals(res[6][1].ast_id, "break_stmt")
    ut:equals(res[7][1].ast_id, "break_stmt")
    res = ut:succeeds(parser.match, parser, "if false then break elseif false then break else break end")
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].value, "false")
    ut:equals(res[2][1].ast_id, "break_stmt")
    ut:equals(res[3].value, "false")
    ut:equals(res[4][1].ast_id, "break_stmt")
    ut:equals(res[5][1].ast_id, "break_stmt")
    res = ut:succeeds(parser.match, parser, "if false then break elseif false then break elseif false then break end")
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].value, "false")
    ut:equals(res[2][1].ast_id, "break_stmt")
    ut:equals(res[3].value, "false")
    ut:equals(res[4][1].ast_id, "break_stmt")
    ut:equals(res[5].value, "false")
    ut:equals(res[6][1].ast_id, "break_stmt")
    ut:equals(res[7], nil)
    res = ut:succeeds(parser.match, parser, "if false then break break else break end")
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].value, "false")
    ut:equals(res[2][1].ast_id, "break_stmt")
    ut:equals(res[2][2].ast_id, "break_stmt")
    ut:equals(res[3][1].ast_id, "break_stmt")
    res = ut:succeeds(parser.match, parser, "if false then break elseif false then break elseif false then break else break end")
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].value, "false")
    ut:equals(res[2][1].ast_id, "break_stmt")
    ut:equals(res[3].value, "false")
    ut:equals(res[4][1].ast_id, "break_stmt")
    ut:equals(res[5].value, "false")
    ut:equals(res[6][1].ast_id, "break_stmt")
    ut:equals(res[7][1].ast_id, "break_stmt")
    res = ut:succeeds(parser.match, parser, "if false then break end")
    ut:equals(res.ast_id, "if_stmt")
    ut:equals(res[1].value, "false")
    ut:equals(res[2][1].ast_id, "break_stmt")
    ut:equals(res[3], nil)
    ut:equals(res[4], nil)
end

function M.test:forstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "for fea = 1, 1, 1 do break end")
    ut:equals(res.ast_id, "for_stmt")
    ut:equals(res.name.name, "fea")
    ut:equals(res.step.value, "1")
    ut:equals(res.first.value, "1")
    ut:equals(res.last.value, "1")
    ut:equals(res.block[1].ast_id, "break_stmt")
    res = ut:succeeds(parser.match, parser, "for fea = 1, 1 do break end")
    ut:equals(res.ast_id, "for_stmt")
    ut:equals(res.name.name, "fea")
    ut:equals(res.step, nil)
    ut:equals(res.first.value, "1")
    ut:equals(res.last.value, "1")
    ut:equals(res.block[1].ast_id, "break_stmt")
end

function M.test:forinstmt(ut)
    local grammar = "rule <- stmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "for few,feww in eqw do break end")
    ut:equals(res.ast_id, "genfor_stmt")
    ut:equals(res.name[1].name, "few")
    ut:equals(res.name[2].name, "feww")
    ut:equals(res.expr[1].name, "eqw")
    ut:equals(res.block[1].ast_id, "break_stmt")
end


function M.test:varexp(ut)
    local grammar = "rule <- varexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "a()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.name, "a")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a[1]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.value, "1")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a[a]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a.a()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(res.name.kind, ".")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a['a']()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.value, "'a'")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a.b:c()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.kind, ".")
    ut:equals(res.name.rhs.name, "b")
    ut:equals(res.kind, ":")
    ut:equals(res.selfname.name, "c")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a[1][2]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.lhs.name, "a")
    ut:equals(res.name.lhs.kind, nil)
    ut:equals(res.name.lhs.rhs.value, "1")
    ut:equals(res.name.rhs.value, "2")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a.b[1].c[2]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.lhs.lhs.lhs.name, "a")
    ut:equals(res.name.lhs.lhs.lhs.kind, ".")
    ut:equals(res.name.lhs.lhs.lhs.rhs.name, "b")
    ut:equals(res.name.lhs.lhs.kind, nil)
    ut:equals(res.name.lhs.lhs.rhs.value, "1")
    ut:equals(res.name.lhs.kind, ".")
    ut:equals(res.name.lhs.rhs.name, "c")
    ut:equals(res.name.kind, nil)
    ut:equals(res.name.rhs.value, "2")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a().b()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name.name, "a")
    ut:equals(#res.name.lhs.arg, 0)
    ut:equals(res.name.kind, ".")
    ut:equals(res.name.rhs.name, "b")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a(b)():c()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.name.name.name, "a")
    ut:equals(res.name.name.arg[1].name, "b")
    ut:equals(#res.name.arg, 0)
    ut:equals(res.kind, ":")
    ut:equals(res.selfname.name, "c")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a()().b()()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.name.lhs.name.name.name, "a")
    ut:equals(#res.name.name.lhs.name.arg, 0)
    ut:equals(#res.name.name.lhs.arg, 0)
    ut:equals(res.name.name.kind, ".")
    ut:equals(res.name.name.rhs.name, "b")
    ut:equals(#res.name.arg, 0)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "(a).a()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.ast_id, "groupexp")
    ut:equals(res.name.kind, ".")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "(a)()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.ast_id, "groupexp")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(parser.match, parser, "a[1]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.value, "1")
    ut:equals(res.literalidx, nil)
    res = ut:succeeds(parser.match, parser, "a[a]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.name, "a")
    ut:equals(res.literalidx, nil)
    res = ut:succeeds(parser.match, parser, "a.a")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.name, "a")
    ut:equals(res.kind, ".")
    res = ut:succeeds(parser.match, parser, "a['a']")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.value, "'a'")
    ut:equals(res.literalidx, nil)
    res = ut:succeeds(parser.match, parser, "a.b.c")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.lhs.name, "a")
    ut:equals(res.lhs.kind, ".")
    ut:equals(res.lhs.rhs.name, "b")
    ut:equals(res.rhs.name, "c")
    ut:equals(res.kind, ".")
    res = ut:succeeds(parser.match, parser, "a[1][2]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.lhs.name, "a")
    ut:equals(res.lhs.kind, nil)
    ut:equals(res.lhs.rhs.value, "1")
    ut:equals(res.rhs.value, "2")
    ut:equals(res.literalidx, nil)
    res = ut:succeeds(parser.match, parser, "a.b[1].c[2]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.lhs.lhs.lhs.name, "a")
    ut:equals(res.lhs.lhs.lhs.kind, ".")
    ut:equals(res.lhs.lhs.lhs.rhs.name, "b")
    ut:equals(res.lhs.lhs.kind, nil)
    ut:equals(res.lhs.lhs.rhs.value, "1")
    ut:equals(res.lhs.kind, ".")
    ut:equals(res.lhs.rhs.name, "c")
    ut:equals(res.literalidx, nil)
    ut:equals(res.rhs.value, "2")
    res = ut:succeeds(parser.match, parser, "a().b")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name.name, "a")
    ut:equals(#res.lhs.arg, 0)
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "b")
    res = ut:succeeds(parser.match, parser, "a()().b")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name.name.name, "a")
    ut:equals(#res.lhs.name.arg, 0)
    ut:equals(#res.lhs.arg, 0)
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "b")
    res = ut:succeeds(parser.match, parser, "(a).a")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.ast_id, "groupexp")
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "a")
end

function M.test:funstmt(ut)
    local grammar = "rule <- funstmt? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "a()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.name, "a")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a[1]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.value, "1")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a[a]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a.a()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(res.name.kind, ".")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a['a']()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.value, "'a'")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a.b:c()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.kind, ".")
    ut:equals(res.name.rhs.name, "b")
    ut:equals(res.kind, ":")
    ut:equals(res.selfname.name, "c")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a[1][2]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.lhs.name, "a")
    ut:equals(res.name.lhs.kind, nil)
    ut:equals(res.name.lhs.rhs.value, "1")
    ut:equals(res.name.rhs.value, "2")
    ut:equals(res.name.kind, nil)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a.b[1].c[2]()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.lhs.lhs.lhs.name, "a")
    ut:equals(res.name.lhs.lhs.lhs.kind, ".")
    ut:equals(res.name.lhs.lhs.lhs.rhs.name, "b")
    ut:equals(res.name.lhs.lhs.kind, nil)
    ut:equals(res.name.lhs.lhs.rhs.value, "1")
    ut:equals(res.name.lhs.kind, ".")
    ut:equals(res.name.lhs.rhs.name, "c")
    ut:equals(res.name.kind, nil)
    ut:equals(res.name.rhs.value, "2")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a().b()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.name.name, "a")
    ut:equals(#res.name.lhs.arg, 0)
    ut:equals(res.name.kind, ".")
    ut:equals(res.name.rhs.name, "b")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a(b)():c()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.name.name.name, "a")
    ut:equals(res.name.name.arg[1].name, "b")
    ut:equals(#res.name.arg, 0)
    ut:equals(res.kind, ":")
    ut:equals(res.selfname.name, "c")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "a()().b()()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.name.lhs.name.name.name, "a")
    ut:equals(#res.name.name.lhs.name.arg, 0)
    ut:equals(#res.name.name.lhs.arg, 0)
    ut:equals(res.name.name.kind, ".")
    ut:equals(res.name.name.rhs.name, "b")
    ut:equals(#res.name.arg, 0)
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "(a).a()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.lhs.ast_id, "groupexp")
    ut:equals(res.name.kind, ".")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(#res.arg, 0)
    res = ut:succeeds(parser.match, parser, "(a)()")
    ut:equals(res.ast_id, "funcall")
    ut:equals(res.name.ast_id, "groupexp")
    ut:equals(#res.arg, 0)
    ut:fails(parser.match, parser, "a()().a")
    ut:fails(parser.match, parser, "a.a")
    ut:fails(parser.match, parser, "(a)")
end

function M.test:vardef(ut)
    local grammar = "rule <- vardef? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "a")
    res = ut:succeeds(parser.match, parser, "a[1]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.value, "1")
    ut:equals(res.kind, nil)
    res = ut:succeeds(parser.match, parser, "a[a]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.name, "a")
    ut:equals(res.kind, nil)
    res = ut:succeeds(parser.match, parser, "a.a")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.name, "a")
    ut:equals(res.kind, ".")
    res = ut:succeeds(parser.match, parser, "a['a']")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name, "a")
    ut:equals(res.rhs.value, "'a'")
    ut:equals(res.kind, nil)
    res = ut:succeeds(parser.match, parser, "a.b.c")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.lhs.name, "a")
    ut:equals(res.lhs.kind, ".")
    ut:equals(res.lhs.rhs.name, "b")
    ut:equals(res.rhs.name, "c")
    ut:equals(res.kind, ".")
    res = ut:succeeds(parser.match, parser, "a[1][2]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.lhs.name, "a")
    ut:equals(res.lhs.kind, nil)
    ut:equals(res.lhs.rhs.value, "1")
    ut:equals(res.rhs.value, "2")
    ut:equals(res.kind, nil)
    res = ut:succeeds(parser.match, parser, "a.b[1].c[2]")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.lhs.lhs.lhs.name, "a")
    ut:equals(res.lhs.lhs.lhs.kind, ".")
    ut:equals(res.lhs.lhs.lhs.rhs.name, "b")
    ut:equals(res.lhs.lhs.kind, nil)
    ut:equals(res.lhs.lhs.rhs.value, "1")
    ut:equals(res.lhs.kind, ".")
    ut:equals(res.lhs.rhs.name, "c")
    ut:equals(res.kind, nil)
    ut:equals(res.rhs.value, "2")
    res = ut:succeeds(parser.match, parser, "a().b")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name.name, "a")
    ut:equals(#res.lhs.arg, 0)
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "b")
    res = ut:succeeds(parser.match, parser, "a()().b")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.name.name.name, "a")
    ut:equals(#res.lhs.name.arg, 0)
    ut:equals(#res.lhs.arg, 0)
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "b")
    res = ut:succeeds(parser.match, parser, "(a).a")
    ut:equals(res.ast_id, "tblidx")
    ut:equals(res.lhs.ast_id, "groupexp")
    ut:equals(res.kind, ".")
    ut:equals(res.rhs.name, "a")
    ut:fails(parser.match, parser, "(a)")
    ut:fails(parser.match, parser, "a()().a()")
    res = ut:succeeds(parser.match, parser, "(a).a")
    ut:fails(parser.match, parser, "(a)")
end

function M.test:grpexp(ut)
    local grammar = "rule <- grpexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "(1)")
    res = ut:succeeds(parser.match, parser, "(few)")
    ut:equals(res.ast_id, "groupexp")
    ut:equals(res.expr.name, "few")
    ut:fails(parser.match, parser, "h(a)")
end

function M.test:funcall(ut)
    local grammar = "rule <- funcall? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, ":a()")
    res = ut:succeeds(parser.match, parser, "()")
    res = ut:succeeds(parser.match, parser, "(a,2,g)")
    res = ut:succeeds(parser.match, parser, "''")
    ut:fails(parser.match, parser, "h(a)")
end

function M.test:funargs(ut)
    local grammar = "rule <- funargs? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "()")
    res = ut:succeeds(parser.match, parser, "'fe'")
    res = ut:succeeds(parser.match, parser, "{}")
    res = ut:succeeds(parser.match, parser, "(1)")
    res = ut:succeeds(parser.match, parser, "(1,2,'joi',few)")
end

function M.test:fundef(ut)
    local grammar = "rule <- fundef? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "function a () return 1 end")
    res = ut:succeeds(parser.match, parser, "function a.a () return 1 end")
    res = ut:succeeds(parser.match, parser, "local function a () return 1 end")
    ut:fails(parser.match, parser, "local function () return 1 end")
    ut:fails(parser.match, parser, "local function a.a () return 1 end")
end

function M.test:fundef_a(ut)
    local grammar = "rule <- fundef_a? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "function() return 1 end")
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.block[1].ast_id, "ret_stmt")
    ut:equals(res.name, nil)
    ut:equals(res.localdef, nil)
end

function M.test:fundef_n(ut)
    local grammar = "rule <- fundef_n? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "function a () return 1 end")
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.block[1].ast_id, "ret_stmt")
    ut:equals(res.name.name, "a")
    ut:equals(res.localdef, nil)
    res = ut:succeeds(parser.match, parser, "function a.a () return 1 end")
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.block[1].ast_id, "ret_stmt")
    ut:equals(res.name.lhs.name, "a")
    ut:equals(res.name.rhs.name, "a")
    ut:equals(res.localdef, nil)
    ut:fails(parser.match, parser, "local function a () return 1 end")
end

function M.test:fundef_l(ut)
    local grammar = "rule <- fundef_l? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "local function a () return 1 end")
    ut:equals(res.ast_id, "fundef")
    ut:equals(res.block[1].ast_id, "ret_stmt")
    ut:equals(res.name.name, "a")
    ut:equals(res.kind, "local")
    ut:fails(parser.match, parser, "local function () return 1 end")
    ut:fails(parser.match, parser, "local function a.a () return 1 end")
end

function M.test:funname(ut)
    local grammar = "rule <- funname? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "a.a.a")
    res = ut:succeeds(parser.match, parser, "a")
    res = ut:succeeds(parser.match, parser, "a:a")
    ut:fails(parser.match, parser, "a[a]")
end

function M.test:funbody(ut)
    local grammar = "rule <- funbody? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local param, body = ut:succeeds(parser.match, parser, "(...) end")
    ut:equals(body, nil)
    ut:equals(param[1].value, "...")
    param, body = ut:succeeds(parser.match, parser, "() return 1 end")
    param, body = ut:succeeds(parser.match, parser, "(a,b) return 1 end")
    ut:equals(param[1].name, "a")
    ut:equals(param[2].name, "b")
end

function M.test:funparm(ut)
    local grammar = "rule <- funparm? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "...")
    ut:equals(res[1].value, "...")
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res[1].name, "a")
    res = ut:succeeds(parser.match, parser, "a,b")
    ut:equals(res[1].name, "a")
    ut:equals(res[2].name, "b")
    res = ut:succeeds(parser.match, parser, "a,...")
    ut:equals(res[1].name, "a")
    ut:equals(res[2].value, "...")
end

function M.test:tabledef(ut)
    local grammar = "rule <- tabledef? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "{}")
    ut:equals(res.value, nil)
    res = ut:succeeds(parser.match, parser, "{[1] = 12, [1] = 12; [1] = 12}")
    ut:equals(res[1].value.value, "12")
    ut:equals(res[1].kind, "expr")
    ut:equals(res[1].key.value, "1")
    ut:equals(res[2].value.value, "12")
    ut:equals(res[2].kind, "expr")
    ut:equals(res[2].key.value, "1")
    ut:equals(res[3].value.value, "12")
    ut:equals(res[3].kind, "expr")
    ut:equals(res[3].key.value, "1")
end

function M.test:fieldlist(ut)
    local grammar = "rule <- {|fieldlist?|} s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "[1] = 12, [1] = 12; [1] = 12")
    ut:equals(res[1].value.value, "12")
    ut:equals(res[1].kind, "expr")
    ut:equals(res[1].key.value, "1")
    res = ut:succeeds(parser.match, parser, "[1] = 12;")
    ut:equals(res[1].value.value, "12")
    ut:equals(res[1].kind, "expr")
    ut:equals(res[1].key.value, "1")
    res = ut:succeeds(parser.match, parser, "[1] = 12;[1] = 12;  [1] = 12;")
    ut:equals(res[1].value.value, "12")
    ut:equals(res[1].kind, "expr")
    ut:equals(res[1].key.value, "1")
end

function M.test:field(ut)
    local grammar = "rule <- field? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "[1] = 12")
    ut:equals(res.value.value, "12")
    ut:equals(res.kind, "expr")
    ut:equals(res.key.value, "1")
    res = ut:succeeds(parser.match, parser, "[a] = 12")
    ut:equals(res.value.value, "12")
    ut:equals(res.kind, "expr")
    ut:equals(res.key.name, "a")
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.value.name, "a")
    ut:equals(res.kind, nil)
    ut:equals(res.key, nil)
    res = ut:succeeds(parser.match, parser, "1")
    ut:equals(res.value.value, "1")
    ut:equals(res.kind, nil)
    ut:equals(res.key, nil)
    res = ut:succeeds(parser.match, parser, "a = 12")
    ut:equals(res.value.value, "12")
    ut:equals(res.kind, "name")
    ut:equals(res.key.name, "a")
end

function M.test:exp(ut)
    local grammar = "rule <- exp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "1 or 1")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], 'or')
    ut:equals(res[3].value, '1')
    res = ut:succeeds(parser.match, parser, "true or true or false and true or true")
    ut:equals(res[1].value, 'true')
    ut:equals(res[2], 'or')
    ut:equals(res[3].value, 'true')
    ut:equals(res[4], 'or')
    ut:equals(res[5][1].value, 'false')
    ut:equals(res[5][2], 'and')
    ut:equals(res[5][3].value, 'true')
    ut:equals(res[6], 'or')
    ut:equals(res[7].value, 'true')
    res = ut:succeeds(parser.match, parser, "name or 2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], 'or')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "name and 2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], 'and')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "name == 2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], '==')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "name..2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], '..')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "name+2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], '+')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "name*2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], '*')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "#name")
    ut:equals(res[1], '#')
    ut:equals(res[2].name, 'name')
    res = ut:succeeds(parser.match, parser, "name^2")
    ut:equals(res[1].name, 'name')
    ut:equals(res[2], '^')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:orexp(ut)
    local grammar = "rule <- orexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "1 or 1")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], 'or')
    ut:equals(res[3].value, '1')
    res = ut:succeeds(parser.match, parser, "true or true or false and true or true")
    ut:equals(res[1].value, 'true')
    ut:equals(res[2], 'or')
    ut:equals(res[3].value, 'true')
    ut:equals(res[4], 'or')
    ut:equals(res[5][1].value, 'false')
    ut:equals(res[6], 'or')
    ut:equals(res[7].value, 'true')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:andexp(ut)
    local grammar = "rule <- andexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "false and true")
    ut:equals(res[1].value, 'false')
    ut:equals(res[2], 'and')
    ut:equals(res[3].value, 'true')
    res = ut:succeeds(parser.match, parser, "1+1 and true")
    ut:equals(res[1][1].value, '1')
    ut:equals(res[2], 'and')
    ut:equals(res[3].value, 'true')
    ut:fails(parser.match, parser, "true or false")
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:logexp(ut)
    local grammar = "rule <- logexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "1 < 2")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], '<')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "2 <= 2")
    ut:equals(res[1].value, '2')
    ut:equals(res[2], '<=')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "2 > 2")
    ut:equals(res[1].value, '2')
    ut:equals(res[2], '>')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "2>=2")
    ut:equals(res[1].value, '2')
    ut:equals(res[2], '>=')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "2 == 2")
    ut:equals(res[1].value, '2')
    ut:equals(res[2], '==')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "2~=1")
    ut:equals(res[1].value, '2')
    ut:equals(res[2], '~=')
    ut:equals(res[3].value, '1')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:catexp(ut)
    local grammar = "rule <- catexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "'fl'..'fefe'")
    ut:equals(res[1].value, "'fl'")
    ut:equals(res[2], '..')
    ut:equals(res[3].value, "'fefe'")
    res = ut:succeeds(parser.match, parser, "a..'222'")
    ut:equals(res[1].name, "a")
    ut:equals(res[2], '..')
    ut:equals(res[3].value, "'222'")
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:sumexp(ut)
    local grammar = "rule <- sumexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "1+1")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], '+')
    ut:equals(res[3].value, '1')
    res = ut:succeeds(parser.match, parser, "1-1")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], '-')
    ut:equals(res[3].value, '1')
    res = ut:succeeds(parser.match, parser, "a-4")
    ut:equals(res[1].name, 'a')
    ut:equals(res[2], '-')
    ut:equals(res[3].value, '4')
    res = ut:succeeds(parser.match, parser, "5-524+f-123-fewf")
    ut:equals(res[1].value, '5')
    ut:equals(res[2], '-')
    ut:equals(res[3].value, '524')
    ut:equals(res[4], '+')
    ut:equals(res[5].name, 'f')
    ut:equals(res[6], '-')
    ut:equals(res[7].value, '123')
    ut:equals(res[8], '-')
    ut:equals(res[9].name, 'fewf')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:prodexp(ut)
    local grammar = "rule <- prodexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "a*2")
    ut:equals(res[1].name, 'a')
    ut:equals(res[2], '*')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "a/2")
    ut:equals(res[1].name, 'a')
    ut:equals(res[2], '/')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "a*2*gb/ge")
    ut:equals(res[1].name, 'a')
    ut:equals(res[2], '*')
    ut:equals(res[3].value, '2')
    ut:equals(res[4], '*')
    ut:equals(res[5].name, 'gb')
    ut:equals(res[6], '/')
    ut:equals(res[7].name, 'ge')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end

function M.test:unexp(ut)
    local grammar = "rule <- unexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "-1")
    ut:equals(res[1], '-')
    ut:equals(res[2].value, '1')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
    res = ut:succeeds(parser.match, parser, "#a")
    ut:equals(res[1], '#')
    ut:equals(res[2].name, 'a')
    res = ut:succeeds(parser.match, parser, "not true")
    ut:equals(res[1], 'not')
    ut:equals(res[2].value, 'true')
    res = ut:succeeds(parser.match, parser, "- - 2")
    ut:equals(res[1], '-')
    ut:equals(res[2], '-')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "- - #######- - - - -2")
    ut:equals(res[1], '-')
    ut:equals(res[2], '-')
    ut:equals(res[3], '#')
    ut:equals(res[4], '#')
    ut:equals(res[5], '#')
    ut:equals(res[6], '#')
    ut:equals(res[7], '#')
    ut:equals(res[8], '#')
    ut:equals(res[9], '#')
    ut:equals(res[10], '-')
    ut:equals(res[11], '-')
    ut:equals(res[12], '-')
    ut:equals(res[13], '-')
    ut:equals(res[14], '-')
    ut:equals(res[15].value, '2')
end

function M.test:powexp(ut)
    local grammar = "rule <- powexp? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "1^2")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], '^')
    ut:equals(res[3].value, '2')
    res = ut:succeeds(parser.match, parser, "1^2^2^2")
    ut:equals(res[1].value, '1')
    ut:equals(res[2], '^')
    ut:equals(res[3].value, '2')
    ut:equals(res[4], '^')
    ut:equals(res[5].value, '2')
    res = ut:succeeds(parser.match, parser, "a")
    ut:equals(res.name, 'a')
end


function M.test:comment(ut)
    local grammar = "rule <- number? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    ut:succeeds(parser.match, parser, "--[[fewfw]]3")
    ut:succeeds(parser.match, parser, "3.0--fewfwe")
    ut:succeeds(parser.match, parser, "3.1416--[=[fewfw]=]")
end

function M.test:ellipsis(ut)
    local grammar = "rule <- literal? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "...")
    ut:equals(res.value, "...")
end

function M.test:number(ut)
    local grammar = "rule <- literal? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    --Tests taken from 5.2 reference manual
    local res = ut:succeeds(parser.match, parser, "3")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '3')
    res = ut:succeeds(parser.match, parser, "3.0")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '3.0')
    res = ut:succeeds(parser.match, parser, "3.1416")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '3.1416')
    res = ut:succeeds(parser.match, parser, "314.16e-2")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '314.16e-2')
    res = ut:succeeds(parser.match, parser, "0.31416E1")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '0.31416E1')
    res = ut:succeeds(parser.match, parser, "0xff")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '0xff')
    res = ut:succeeds(parser.match, parser, "0x0.1E")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '0x0.1E')
    res = ut:succeeds(parser.match, parser, "0xA23p-4")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '0xA23p-4')
    res = ut:succeeds(parser.match, parser, "0X1.921FB54442D18P+1")
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '0X1.921FB54442D18P+1')
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
    local grammar = "rule <- literal? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, [=====["gvrewgr"]=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, '"gvrewgr"')
    res = ut:succeeds(parser.match, parser, [=====['few']=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, "'few'")
    res = ut:succeeds(parser.match, parser, [=====[[[fe]]]=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, "[[fe]]")
    res = ut:succeeds(parser.match, parser, [=====[[=[dfew]=]]=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, "[=[dfew]=]")
    res = ut:succeeds(parser.match, parser, [=====["'[['"]=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, [=["'[['"]=])
    ut:fails(parser.match, parser,    [=====["hiohjoi']=====])
    res = ut:succeeds(parser.match, parser, [=====[[[
                                                fee]]]=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, [=[[[
                                                fee]]]=])
    res = ut:succeeds(parser.match, parser, [=====["\"\123\n\t\s\r"]=====])
    ut:equals(res.ast_id, "literal")
    ut:equals(res.value, [["\"\123\n\t\s\r"]])
end

function M.test:name(ut)
    local grammar = "rule <- name? s (!./''=>error)\n" .. M.grammar
    local parser = ut:succeeds(self.compile, grammar, self.defs)
    local res = ut:succeeds(parser.match, parser, "few")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "few")
    res = ut:succeeds(parser.match, parser, "few_few")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "few_few")
    res = ut:succeeds(parser.match, parser, "few21_few21")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "few21_few21")
    res = ut:succeeds(parser.match, parser, "_few")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "_few")
    res = ut:succeeds(parser.match, parser, "functions")
    ut:equals(res.ast_id, "name")
    ut:equals(res.name, "functions")
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
