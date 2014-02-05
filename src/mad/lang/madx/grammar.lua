local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.lang.lua.grammar

SYNOPSIS
  local grammar = require"mad.lang.lua.grammar".grammar
  
DESCRIPTION
  Returns the regex-based grammar of Lua.

RETURN VALUES
  The grammar

SEE ALSO
  None
]]

-- grammar ---------------------------------------------------------------------

M.grammar = [=[
-- top level rules

    chunk       <- ((''=>setup) {(stmt s';'sp)*}  s(!./''=>error))    -> chunk

-- statement
    
    stmt        <- assignstmt / defassign / lblstmt / cmdstmt / retstmt
    assignstmt  <- real? const? assign
    lblstmt     <- (name s':'sp name (s','?sp attrlist)?                            sp) -> lblstmt
    cmdstmt     <- (name s','?sp attrlist?                                          sp) -> cmdstmt
    retstmt     <- (return explist?                                                 sp) -> retstmt
    assign      <- (name s'='sp exp                                                 sp) -> assign
    defassign   <- (name s':'s'='sp exp                                             sp) -> defassign
    
    attr        <- (assign / defassign / exp                                        sp) -> attr
    attrlist    <- attr (s','sp attr)*
    

-- expressions

    exp         <- ({ sumexp }                                                      sp) -> exp
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

    sumop       <- s{'+' / '-'} sp
    prodop      <- s{'*' / '/'} sp
    unop        <- s{'-' / '+'} sp
    powop       <- s{'^'} sp
    
-- keywords

    keyword     <- (real / const / return)
    
    return      <- s[rR][eE][tT][uU][rR][nN]sp
    real        <- s[rR][eE][aA][lL]sp
    const       <- s[cC][oO][nN][sS][tT]sp
    
-- lexems

    literal     <- (s{"nil" / "false" / "true" / number / string}                   sp) -> literal
    
    name        <- ((s !keyword {ident})                                            sp) -> name
    string      <- s(sstring)
    number      <- s( decnum )

-- basic lexems

    sstring     <- '"' ssclose
    ssclose     <- '"' / ch ssclose

    decnum      <- ((num ('.' num / '.')?) / ('.' num)) ([eE] sign? num)?

    ident       <- [A-Za-z_][A-Za-z0-9_.$]*
    e           <- ![A-Za-z0-9_]
    num         <- [0-9]+
    sign        <- [-+]
    any         <- ch / nl
    s           <- (ws / nl / cmt)*

    
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
M.test = require "mad.lang.lua.test.grammar"
--end]]




-- end ------------------------------------------------------------------------

return M
