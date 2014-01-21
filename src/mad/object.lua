local M = { help={}, test={}, _id="object" }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.object -- transform Lua tables into general purpose objects

SYNOPSIS
  object = require "mad.object"
  var = object [string] table

DESCRIPTION
  The module mad.object *transforms* any table into an object with inheritance of
  properties and callable semantic. Hence an object is a table that can be used
  as a constructor (a function), an object (a table) or a class (a metatable).
  
  The returned object has its class (its constructor) set as metatable and
  inherits all properties of its class autmatically, implementing a prototype
  language.

  The optional string argument is stored into the property _id of the object.

RETURN VALUES
  The table passed as argument, not a copy!

ERRORS
  If the constructor does not receive an optional string and a table, an invalid
  argument error is raised.
  If the table passed is already an opbject, an invalid argument error is raised.

EXAMPLES
  object = require "mad.object"
  my_a = object 'a' { myflag = true }         -- _id = 'a' (implicit)
  my_b = object { _id = 'b', myflag = true }  -- _id = 'b' (explicit)
  my_c = object { myflag = false }            -- _id = nil

SEE ALSO
  mad.module, mad.element, mad.sequence, mad.beam
]]

-- locals ---------------------------------------------------------------------

local getmetatable, setmetatable = getmetatable, setmetatable

-- methods ---------------------------------------------------------------------

-- return the direct parent
function M:super()
  return getmetatable(self)
end

-- return the parent id or nil
function M:isa(id)
  local a = self;

  if type(id) == "string" then
    while a ~= nil and rawget(a, "_id") ~= id do
      a = getmetatable(a)
    end
    return a

  elseif type(id) == "table" then
    while a ~= nil and a ~= id do
      a = getmetatable(a)
    end
    return a
  end

  error("invalid parent id, should be either an object or a string")
end

-- return a clone of self
function M:clone(id)
  if type(id) == "string" or id == nil then
    local c = {} -- clone
    for k,v in pairs(self) do
      c[k] = v
    end
    return rawset(setmetatable(c, getmetatable(self)), "_id", id)
  end

  error ("invalid clone argument, should be: parent:clone [id_string]")
end

-- return value(s) of each key
function M:get(key)
  if type(key) == "table" then
    local t = {}
    for i,k in ipairs(key) do
      t[i] = self[k]
    end
    return table.unpack(t)
  end
  return self[key];
end

-- set key, value pair(s)
function M:set(key, val)
  if type(key) == "table" then
    for k,v in pairs(key) do
      self[k] = v
    end
  end
  self[key] = val;
end

-- metamethods -----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

mt.__call = function (self, a)

  if not rawget(self, "__call") then
    rawset(self, "__index", self)         -- inheritance
    rawset(self, "__call", mt.__call)     -- constructor call
  end

  -- parent {}
  if type(a) == "table" then
    return setmetatable(a, self)
  end

  -- parent 'id' {}
  if type(a) == "string" then
    return function (t)
      if type(t) == "table" then
        return rawset(setmetatable(t, self), "_id", a)
      end
      error ("invalid constructor argument, should be: parent [id_string] prop_table")
    end
  end

  error ("invalid constructor argument, should be: parent [id_string] prop_table")
end

-- tests -----------------------------------------------------------------------

M.test.self = function ()

  -- helper
  local print_obj = function (s,o)
    print("---")
    print(s, " = ", o)
    print(s, "._id = ", o._id)
    local super = o:super()
    if super then
      print(s, ".super = ", super)
      print(s, ".super._id = ", super._id)
    end
  end

  local object = M
  print("M = ", M)
  print("mt = ", mt)
  print_obj("object", object)

  -- simple instance of "object"
  local any = object { _id = "any" }

  -- new objects as instances of "object"
  local bend = object "bend" { len = 2 }
  local quad = object "quad" { len = 1 }

  -- new objects as instances of previous objects
  local mb = bend "mb" { at = 1 }
  local mq = quad "mq" { at = 3 }
  local cpy = mb:clone "cpy"

  -- array of objects
  local arr = {}
  for i = 1,5 do
    arr[i] = cpy { at = i }
  end

  -- print inheritance chain
  print_obj("any" , any)
  print_obj("bend", bend); print_obj("mb", mb)
  print_obj("quad", quad); print_obj("mq", mq)
  print_obj("cpy" , cpy)

  -- check lookup chain
  print("name = ", mb._id, "at = ", mb.at, "len = ", mb.len)
  print("name = ", mq._id, "at = ", mq.at, "len = ", mq.len)

  -- check scan
  print("keys of mb")
  for k,v in pairs(mb) do
    print(k, "=", v)
  end

  -- check array
  for i = 1,#arr do
    print_obj("arr["..i.."]", arr[i])
    for k,v in pairs(arr[i]) do
      print(k, "=", v)
    end
  end

  return 9, 9
end

-- end -------------------------------------------------------------------------
return M
