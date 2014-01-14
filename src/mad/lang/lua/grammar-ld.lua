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

    chunk       <- block
    block       <- stmt* retstmt?

-- statements

    stmt        <- ';' / label / break / goto name / do_block / fundef / funcall
                    / varlist '=' explist
                    / local namelist ('=' explist)?
                    / while exp do_block
                    / repeat block until exp
                    / if exp then block (elseif exp then block)* (else block)? end
                    / for name '=' exp ',' exp (',' exp)? do_block
                    / for namelist in explist do_block

    do_block    <- do block end

-- extra stmts

    label       <- '::' name '::'
    retstmt     <- return explist? ';'?

-- expressions

--*    exp         <- nil / false / true / number / string / '...' / 
--                   fundef_a / prefixexp / tablector /
--                   exp binop exp / unop exp

    exp         <- expval exp_r / unop exp exp_r
    exp_r       <- !. / binop exp exp_r
    expval      <- nil / false / true / number / string / '...' / 
                   fundef_a / prefixexp / tablector

--* prefixexp   <- var / funcall / '(' exp ')'
    prefixexp   <- name prefixexp_r / '(' exp ')' prefixexp_r

    explist     <- exp (',' exp)*

    index       <- '[' exp ']' / '.' name
    call        <- args / ':' name args
    suffixexp   <- index / call
    prefixexp_r <- !. / suffixexp prefixexp_r

-- variables

--* var         <- name / prefixexp '[' exp ']' / prefixexp '.' name
    var         <- name / prefixexp index
    varlist     <- var (',' var)*

-- function invocations

--* funcall     <- prefixexp args / prefixexp ':' name args
    funcall     <- prefixexp call
    args        <- '(' explist? ')' / tablector / string

-- function definitions

    fundef      <- fundef_n / fundef_l
    fundef_a    <- function funbody             -- anonymous
    fundef_n    <- function funname funbody     -- named
    fundef_l    <- local function name funbody  -- local named

    funname     <- name ('.' name)* (':' name)?
    funbody     <- '(' parlist? ')' block end
    parlist     <- namelist (',' '...')? / '...'

-- table definitions

    tablector   <- '{' fieldlist? '}'
    fieldlist   <- field (fieldsep field)* fieldsep?
    field       <- '[' exp ']' '=' exp / name '=' exp / exp
    fieldsep    <- ',' / ';'

-- operators

    binop       <- '+' / '-' / '*' / '/' / '^' / '%' / '..' / '<=' / '<' / '>=' / '>' / '==' / '~=' / and / or
    unop        <- '-' / not / '#'

-- basic lexems

    name        <- !keyword ident
    namelist    <- name (',' name)*

    string      <- sstring / lstring

    sstring     <- {:qt: ['"] :} ssclose
    ssclose     <- =qt / '\' =qt ssclose / ch ssclose

    lstring     <- '[' {:eq: '='* :} '[' lsclose
    lsclose     <- ']' =eq ']' / any lsclose

     comment    <- '--' ch* nl
    lcomment    <- '--' lstring

    number      <- decnum / hexnum
    decnum      <-      num ('.' num)? ([eE] sign? num)?
    hexnum      <- '0x' hex ('.' hex)? ([pP] sign? hex)?

    ident       <- [A-Za-z_][A-Za-z0-9_]*
    e           <- ![A-Za-z0-9_]
    hex         <- [0-9A-Fa-f]+
    num         <- [0-9]+
    sign        <- [-+]
    any         <- ch / nl
    s           <- (ws / nl)*

-- keywords

    keyword     <- and / break / do / else / elseif / end / false / for / function / goto / if / in / local / nil / not /
                   or / repeat / return / then / true / until / while

    and         <- 'and'      e
    break       <- 'break'    e
    do          <- 'do'       e
    else        <- 'else'     e
    elseif      <- 'elseif'   e
    end         <- 'end'      e
    false       <- 'false'    e 
    for         <- 'for'      e
    function    <- 'function' e
    goto        <- 'goto'     e
    if          <- 'if'       e
    in          <- 'in'       e
    local       <- 'local'    e
    nil         <- 'nil'      e
    not         <- 'not'      e 
    or          <- 'or'       e
    repeat      <- 'repeat'   e
    return      <- 'return'   e
    then        <- 'then'     e
    true        <- 'true'     e
    until       <- 'until'    e
    while       <- 'while'    e

]=]
-- escape characters, must be outside long strings
.. "ws <- [ \t\r]"
.. "ch <- [^\n]"
.. "nl <- [\n]"

return M
