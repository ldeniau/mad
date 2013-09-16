local M = { _id="object", _author="LD", _year=2013, help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  object -- transform tables into general purpose objects

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

-- require ---------------------------------------------------------------------

local module = require "mad.module"

-- local -----------------------------------------------------------------------

-- functions -------------------------------------------------------------------

-- methods ---------------------------------------------------------------------

-- metamethods -----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

mt.__call = function (t, o)
  ...
end

-- tests -----------------------------------------------------------------------

M.test.self = function (...)
  ...
  return passed, failed, title
end

-- end -------------------------------------------------------------------------
return (require "mad.module")(M)
