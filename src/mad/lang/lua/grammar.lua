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

--if mad_loadtest then
M.test = require "mad.lang.lua.test.grammar"
--end]]




-- end ------------------------------------------------------------------------

return M
