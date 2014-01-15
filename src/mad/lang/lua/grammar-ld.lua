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

--* prefixexp   <- var / funcall / s'(' exp s')'
    prefixexp   <- name prefixexp_r / s'(' exp s')' prefixexp_r

    explist     <- exp (s',' exp)*

    index       <- s'[' exp s']' / s'.' name
    call        <- args / s':' name args
    suffixexp   <- index / call
    prefixexp_r <- s( suffixexp prefixexp_r )?

-- variables

--* var         <- name / prefixexp s'[' exp s']' / prefixexp s'.' name
    var         <- prefixexp index / name --TODO index will always be eaten by suffixexp in prefixexp. pref index/name
    varlist     <- var (s',' var)*

-- function invocations

--* funcall     <- prefixexp args / prefixexp s':' name args
    funcall     <- prefixexp call --TODO remove call? Won't it always be eaten by suffixexp? pref call
    args        <- s'(' explist? s')' / tablector / string

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
    number      <- s( decnum / hexnum )

-- basic lexems

    sstring     <- {:qt: ['"] :} ssclose
    ssclose     <- =qt / '\' =qt ssclose / ch ssclose

    lstring     <- '[' {:eq: '='* :} '[' lsclose
    lsclose     <- ']' =eq ']' / any lsclose

    decnum      <-      num ('.' num)? ([eE] sign? num)?
    hexnum      <- '0x' hex ('.' hex)? ([pP] sign? hex)?

    ident       <- [A-Za-z_][A-Za-z0-9_]*
    e           <- ![A-Za-z0-9_]
    hex         <- [0-9A-Fa-f]+
    num         <- [0-9]+
    sign        <- [-+]
    any         <- ch / nl
    s           <- (ws / nl / cmt)*

-- keywords

    keyword     <- and / break / do / else / elseif / end / false / for / function / goto / if / in / local / nil / not /
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

    cmt    <- '--' ( lstring / ch* nl )

]=]
-- escape characters, must be outside long strings
.. "ws <- [ \t\r]"
.. "ch <- [^\n]"
.. "nl <- [\n]"

return M
