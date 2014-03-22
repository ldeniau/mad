local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.lang.madx.grammar

SYNOPSIS
  grammar = require"mad.lang.madx.grammar".grammar
  
DESCRIPTION
  Returns the regex-based grammar of MAD-X.

RETURN VALUES
  The grammar

SEE ALSO
  None
]]

-- grammar ---------------------------------------------------------------------

M.grammar = [=[
-- top level rules

    chunk       <- ((''=>setup) (stmtnum)* s(!./''=>error))                             -> chunk
    stmtnum     <- (stmt s';'sp (stmt s';'sp)^-1000)                                    => stmtnum
    block       <- (s'{'sp (stmt s';'sp)* s'}'                                      sp) -> block

-- statement
    
    stmt        <- (s( assignstmt / macrodef / macrocall / defassign / linestmt 
                    / lblstmt / cmdstmt / retstmt / ifstmt / whilestmt )sp)
                    
    assignstmt  <- (real? const? assign)
    lblstmt     <- (name s':'sp sc name (s','?sp attrlist)?               sp) -> lblstmt
    cmdstmt     <- (sc name s','?sp attrlist?                             sp) -> cmdstmt
    retstmt     <- (return explist?                                                 sp) -> retstmt
    linestmt    <- (name ls':'sp line ls'='sp linector                              sp) -> linestmt
    ifstmt      <- ({if s'('sp exp s')'sp block
                    (elseif s'('sp exp s')'sp block)*
                    (else block)?}                                                  sp) -> ifstmt
    whilestmt   <- (while s'('sp exp s')'sp block                                   sp) -> whilestmt

-- attributes

    assign      <- (name s'='sp exp                                                 sp) -> assign
    defassign   <- (name s':'s'='sp exp                                             sp) -> defassign
    
    attr        <- (attrassign / defassign / exp                                    sp) -> attr
    attrlist    <- (attr (s','sp attr)*)
    
    attrassign  <- ( ((name=>chkeystr) s'='sp madstr)                                          -> keystr
                   / ((name=>chkeystrtbl) s'='sp s'{'?sp (madstr (s','sp madstr)*)? s'}'?sp)   -> keystrtbl
                   / assign)
                   
   sc           <- (''=>saveclasspre)

-- macro

    macrocall   <- (exec s','sp name (s'('sp macroarg s')')?                        sp) -> macrocall
    macrodef    <- (name parlist? s':'sp macro s'='?sp macroblock                   sp) -> macrodef
    
    macroarg    <- (s{'$'?(number? ident / number)} sp (s','sp s{'$'?(number? ident / number)} sp )*)
    
    macroblock  <- s'{'sp {((!('{'/'}') any) / balanced)*} '}'sp
    parlist     <- (s'('sp macrostr (s','sp macrostr )* s')'                        sp) -> parlist
    macrostr    <- s(string->literal / {[^%s),]+}) sp
    balanced    <- '{' ((!('{'/'}') any) / balanced)* '}'
    
-- line

    linector    <- (ls'('sp linedef ls')'                                           sp) -> linector
    linedef     <- (linepart (ls','sp linepart)*)
    linepart    <- (ls(invert / times / ls name / linector)                         sp) -> linepart
    invert      <- (ls'-'sp linepart                                                sp) -> invertline
    times       <- (ls((number->literal)sp ls'*'sp linepart)                        sp) -> timesline

-- expressions

    exp         <- ({ sumexp }                                                      sp) -> exp
    orexp       <- ({ andexp   ( orop    andexp  )* }                               sp) -> orexp
    andexp      <- ({ logexp   ( andop   logexp  )* }                               sp) -> andexp
    logexp      <- ({ sumexp   ( logop   sumexp  )* }                               sp) -> logexp
    sumexp      <- ({ prodexp  ( sumop   prodexp )* }                               sp) -> sumexp
    prodexp     <- ({ unexp    ( prodop  unexp   )* }                               sp) -> prodexp
    unexp       <- ({          ( unop*   powexp  )  }                               sp) -> unexp
    powexp      <- ({ valexp   ( powop   valexp  )* }                               sp) -> powexp
    
    valexp      <- literal / grpexp / funcall / name / vector
    grpexp      <- (s'('sp exp s')'                                                 sp) -> grpexp
    vector      <- (s'{'sp explist s'}'                                             sp) -> vector
    
    explist     <- exp (s','sp exp)*
    
-- function call

    funcall     <- (name s'('sp {|explist?|} s')'                                   sp) -> funcall

-- operators

    andop       <- s{~ '&&'->'and' ~} sp -> substCap
    orop        <- s{~ '||'->'or' ~} sp -> substCap
    logop       <- s{ '==' / ({~'<>'->'~='~} -> substCap) / '<=' / '>=' / '<' / '>' } sp
    sumop       <- s{'+' / '-'} sp
    prodop      <- s{'*' / '/'} sp
    unop        <- s({'-'} / '+') sp -- Implicit + if - isn't present.
    powop       <- s{'^'} sp
    
    
    
-- keywords

    keyword     <- (real / const / return / line / if / elseif / else / while / macro / exec)
    
    return      <- s[rR][eE][tT][uU][rR][nN]sp
    real        <- s[rR][eE][aA][lL]sp
    const       <- s[cC][oO][nN][sS][tT]sp
    line        <- s[lL][iI][nN][eE]sp
    if          <- s[iI][fF]sp
    elseif      <- s[eE][lL][sS][eE][iI][fF]sp
    else        <- s[eE][lL][sS][eE]sp
    while       <- s[wW][hH][iI][lL][eE]sp
    macro       <- s[mM][aA][cC][rR][oO]sp
    exec        <- s[eE][xX][eE][cC]sp
    
-- lexems

    literal     <- (s{number / string}                                              sp) -> literal
    
    name        <- ((s !keyword {ident})                                            sp) -> name
    madstr      <- s(string / ((''->'"') {(!(','/';') any)+} (''->'"'))             sp) -> literal
    string      <- s(sstring)
    number      <- s( decnum )

-- basic lexems

    sstring     <- '"' ssclose
    ssclose     <- '"' / ch ssclose

    decnum      <- {~((num ('.' num / '.'->'.0')?) / (('.'->'0.') num)) ([eE] sign? num)?~}

    ident       <- [A-Za-z_][A-Za-z0-9_.$]*
    e           <- ![A-Za-z0-9_]
    num         <- [0-9]+
    sign        <- [-+]
    any         <- ch / nl
    s           <- (ws / nl / cmt)*
    ls          <- s'&'? -- In MAD8/9, & means line-continuation.

    
-- comments

    cmt    <- ( (('!'/'//') ( ch* (nl/!.) )) / ('/*' (!'*/' any)* '*/' ) )

-- saving position
    sp     <- (''=>savePos)

]=]
-- escape characters, must be outside long strings
.. "ws <- [ \t\r]"
.. "ch <- [^\n]"
.. "nl <- [\n] -> newLine"

-- test -----------------------------------------------------------------------

--if mad_loadtest then
M.test = require "mad.lang.madx.test.grammar"
--end]]

-- end ------------------------------------------------------------------------

return M
