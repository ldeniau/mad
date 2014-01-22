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

require"mad.lang.lua.test.grammar-spaces"(M)



-- end ------------------------------------------------------------------------

return M
