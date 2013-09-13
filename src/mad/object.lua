local M = { _id="object", _author="LD", _year=2013, help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.object -- transform tables into general purpose objects

SYNOPSIS
  local object = require "mad.object"
  local var = object [string] table

DESCRIPTION
  The module mad.object transforms any table into an object with inheritance of
  properties and callable semantic. Hence an object is a table that can be used
  as a constructor (a function), an object (a table) or a class (a metatable).
  
  The returned object has its class (its constructor) set as metatable and
  inherits all properties of its class autmatically.

  The optional string argument is stored into the property _id of the object,
  default _id = "none".

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

-- local -----------------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

-- metamethods -----------------------------------------------------------------

mt.__call = function (t, o)
    if type(o) == "table" then
      o._id = o._id or "none"
      t.__index = t
      t.__call  = mt.__call
      return setmetatable(o, t)
    end

    if type(o) == "string" then
      return function (so)
        so._id = o
        return mt.__call(t, so)
      end
    end

    error ("invalid constructor argument, should be: ctor [id] table") 
  end

-- tests -----------------------------------------------------------------------

M.test.self = function (...)

  -- helper
  local print_obj = function (o)
    print("o = ", o)
    print("o._id = ", o._id)
    local mt = getmetatable(o)
    if mt then
      print("o._mt = ", mt)
      print("o._mt._id = ", mt._id)
    end
  end

  local object = M
  print("mt = ", mt)
  print_obj(object)

  -- simple instance of "object"
  local any = object {}

  -- new objects as instances of "object"
  local bend = object "bend" { len = 2 }
  local quad = object "quad" { len = 1 }

  -- new objects as instances of previous objects
  local mb = bend "mb" { at = 1 }
  local mq = quad "mq" { at = 3 }

  -- print inheritance chain
  print_obj(any)
  print_obj(bend); print_obj(mb)
  print_obj(quad); print_obj(mq)

  -- check lookup chain
  print("name = ", mb._id, "at = ", mb.at, "len = ", mb.len)
  print("name = ", mq._id, "at = ", mq.at, "len = ", mq.len)

  return 9, 9
end

-- end -------------------------------------------------------------------------
return (require "mad.module")(M)
