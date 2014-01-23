local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  object -- this a template example, what follows as no meaning

SYNOPSIS
  local object = require "mad.object"
  local var = object [string] table

DESCRIPTION
  The module mad.object transforms any table into an object with inheritance of
  properties and callable semantic. Hence an object is a table that can be used
  as a constructor (a function), an object (a table) or a class (a metatable).

RETURN VALUES
  The table passed as argument.

ERRORS
  If the constructor does not receive an optional string and a table, an invalid
  argument error is raised. 

EXAMPLES
  local object = require "mad.object"
  local myobj = object "myobj" { myflag = true }
  local myfoo = object { myflag = false } -- no id -> "none"

SEE ALSO
  None
]]

-- requires --------------------------------------------------------------------

-- locals ----------------------------------------------------------------------

-- functions -------------------------------------------------------------------

-- methods ---------------------------------------------------------------------

-- metamethods -----------------------------------------------------------------

local MT = {}; setmetatable(M, MT)

-- tests -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M
