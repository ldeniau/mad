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

    chunk       <- ((''=>setup) block s(!./''=>error))                                  -> chunk
    block       <- ({stmt* retstmt?}                                                sp) -> block

-- statements

    stmt        <- s(
                      ';'sp / label / (break                                        sp) -> breakstmt 
                    / (goto name                                                    sp) -> gotostmt
                    / (do_block                                                     sp) -> dostmt 
                    / fundef
                    / ({|varlist|} s'='sp {|explist|}                               sp) -> assign 
                    / funstmt
                    / (local {|namelist|} (s'='sp {|explist|})?                     sp) -> locassign
                    / (while exp do_block                                           sp) -> whilestmt
                    / (repeat block until exp                                       sp) -> repeatstmt
                    / ({if exp then block 
                        (elseif exp then block)*
                        (else block)? end}                                          sp) -> ifstmt
                    / (for name s'='sp exp s','sp exp (s','sp exp)? do_block        sp) -> forstmt
                    / (for {|namelist|} in {|explist|} do_block                     sp) -> forinstmt
                    )

    do_block    <- do block end

-- extra stmts

    label       <- ({s'::'sp name s'::'}                                            sp) -> label
    retstmt     <- ({return explist? s';'?}                                         sp) -> retstmt

-- expressions

    exp         <- ({ orexp }                                                       sp) -> exp
    orexp       <- ({ andexp   ( or      andexp  )* }                               sp) -> orexp
    andexp      <- ({ logexp   ( and     logexp  )* }                               sp) -> andexp
    logexp      <- ({ catexp   ( logop   catexp  )* }                               sp) -> logexp
    catexp      <- ({ sumexp   ( catop   sumexp  )* }                               sp) -> catexp
    sumexp      <- ({ prodexp  ( sumop   prodexp )* }                               sp) -> sumexp
    prodexp     <- ({ unexp    ( prodop  unexp   )* }                               sp) -> prodexp
    unexp       <- ({          ( unop*   powexp  )  }                               sp) -> unexp
    powexp      <- ({ valexp   ( powop   valexp  )* }                               sp) -> powexp
    
    valexp      <- literal / tabledef / fundef_a / lambda / varexp
    varexp      <- ((name   / grpexp) (tableidx / funcall)*                         sp) -> varexp
    grpexp      <- (s'('sp exp s')'                                                 sp) -> grpexp
    
    explist     <- exp (s','sp exp)*

-- variable definitions (only on lhs of '=')

    vardef      <- ((name / grpexp varsfx) varsfx*                                  sp) -> vardef
    varsfx      <- funcall* tableidx
    varlist     <- vardef (s',' vardef)*

-- function definitions & call

    fundef      <- fundef_n / fundef_l
    fundef_a    <- (function funbody                                                sp) -> fundef_a -- anonymous
    fundef_n    <- (function funname funbody                                        sp) -> fundef_n -- named
    fundef_l    <- (local function name funbody                                     sp) -> fundef_l -- local named

    funname     <- ({|name (s'.'sp name)*|} (s':'sp name)?                          sp) -> funname
    funbody     <- (s'('sp {|funparm?|} s')'sp block end                            sp) -> funbody
    funparm     <- ({|namelist|}(s','sp s ellipsis->literal)? /s ellipsis->literal  sp) -> funparm

    funstmt     <- ((name / grpexp) varsfx* funcall+                                sp) -> funstmt

    funcall     <- (( s{':'}sp name )? funargs                                      sp) -> funcall
    funargs     <- s'('sp explist? s')'sp / tabledef / (string->literal)
    
    lambda      <- (s'\'sp {|(namenosp (s','sp namelist)?)?|} ( {exp} / (s'('sp {|explist|} s')') ) sp) -> lambda

-- table definitions & access

    tabledef    <- (s'{' { fieldlist? } s'}'                                        sp) -> tabledef
    fieldlist   <- field (fieldsep field)* fieldsep?
    field       <- ({s{'['}sp exp s']'sp s'='sp exp / name s'='sp exp / exp}        sp) -> field
    fieldsep    <- s','sp / s';'sp
    
    tableidx    <- (s{'['}sp exp s']'sp / s{'.'}sp name                             sp) -> tableidx

-- operators

    logop       <- s{'<=' / '<' / '>=' / '>' / '==' / '~='} sp
    catop       <- s{'..'} sp
    sumop       <- s{'+' / '-'} sp
    prodop      <- s{'*' / '/' / '%'} sp
    unop        <- s{not / '#' / '-'} sp
    powop       <- s{'^'} sp
    
-- lexems

    literal     <- (s{nil / false / true / number / string / ellipsis}              sp) -> literal
    
    name        <- ((s !keyword {ident})                                            sp) -> name
    namenosp    <- ((  !keyword {ident})                                            sp) -> name
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

    and         <- s{'and'}    e sp
    break       <- s'break'    e sp
    do          <- s'do'       e sp
    else        <- s'else'     e sp
    elseif      <- s'elseif'   e sp
    end         <- s'end'      e sp
    false       <- s'false'    e sp
    for         <- s'for'      e sp
    function    <- s'function' e sp
    goto        <- s'goto'     e sp
    if          <- s'if'       e sp
    in          <- s'in'       e sp
    local       <- s'local'    e sp
    nil         <- s'nil'      e sp
    not         <- s'not'      e sp
    or          <- s{'or'}     e sp
    repeat      <- s'repeat'   e sp
    return      <- s'return'   e sp
    then        <- s'then'     e sp
    true        <- s'true'     e sp
    until       <- s'until'    e sp
    while       <- s'while'    e sp
    
-- comments

    cmt    <- '--' ( lstring / ch* (nl/!.) ) => savePos

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
