local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.object -- creates objects

SYNOPSIS
  object = require"mad.object"
  obj1 = object {}               -- create a new empty object
  obj2 = object { ... }          -- create a new object with values

DESCRIPTION
  The module mad.object creates new objects from tables that become instances
  of their parent, with callable semantic (i.e. constructor).
  
  The returned object has its parent (its constructor) set as metatable and
  inherits all properties of it autmatically, hence implementing a prototype
  language.

  Hence an object is a 'table' that can be used as a constructor (a function)
  to create new instances of itself, an object (a table) or a class/parent
  (a metatable).

  The string argument is stored into the property 'name' of the object.

RETURN VALUES
  The new object

ERRORS
  If the object does not receive a table, an invalid argument error is raised.

EXAMPLES
  Object = require"mad.object"
  Point = Object {}                     -- Point derives from Object
  p0 = Point { x=0, y=0 }               -- p0 is an instance of Point
  p1 = Point { x=1, y=1 }               -- p1 is an instance of Point
  p2 = p1:cpy()                         -- p2 is a copy of p1
  p1:set { x=-1, y=-2 }                 -- set p1.x and p1.y (slow)
  p1.x, p1.y = 1, 2                     -- set p1.x and p1.y (faster)

SEE ALSO
  mad.module, mad.element, mad.sequence, mad.beam
]]

-- locals ----------------------------------------------------------------------

local type, getmetatable, setmetatable = type, getmetatable, setmetatable
local pairs = pairs

local MT = {}; setmetatable(M, MT) -- make this module the root of all objects

-- members ---------------------------------------------------------------------

M.is_object = true
M.name = 'object'

-- methods ---------------------------------------------------------------------

-- return the next parent
function M:spr()
  return getmetatable(self)
end

-- return the parent id or nil
function M:isa(id)
  local a = getmetatable(self);
  while a ~= nil and a ~= id do a = getmetatable(a) end
  return a
end

-- set values taken from iterator
function M:set(a)
  for k,v in pairs(a) do self[k] = v end
  return self
end

-- make a copy
function M:cpy()
  return setmetatable({}, getmetatable(self)):set(self)
end

-- metamethods -----------------------------------------------------------------

-- constructor
function MT:__call(a)
  if type(a) == 'table' then
    if not rawget(self, '__call') then
      self.__index = self         -- inheritance
      self.__call  = MT.__call    -- constructor
    end
    return setmetatable(a, self)
  end
  error ("invalid constructor argument, table expected")
end

-- tests -----------------------------------------------------------------------

function M.test:setUp()
end

function M.test:tearDown()
end

function M.test:spr(ut)
    local object = M
    local any = ut:succeeds(object, 'any')
    local sup = ut:succeeds(any.super, any)
    ut:equals(sup, object)
end

function M.test:isa(ut)
    local object = M
    local any = object "any" {  }
    local is = ut:succeeds(any.isa, any, object.name)
    ut:equals(is, object)
    is = ut:succeeds(any.isa, any, object)
    ut:equals(is, object)
    ut:fails(any.isa, any, 1)
    is = ut:succeeds(any.isa, any, "bollock")
    ut:equals(is, nil)
end

function M.test:ctor(ut)
    local object = M
    local obj1 = ut:succeeds(object, "obj1")
    ut:succeeds(obj1, { val1 = 1 })
    local obj2 = ut:succeeds(obj1,   "obj2")
    ut:succeeds(obj2, { val2 = 2 })
    ut:equals(obj1.val1, 1)
    ut:equals(obj2.val2, 2)
    ut:equals(obj2.val1, 1)
    obj1.val3 = 3
    ut:equals(obj2.val3, obj1.val3)
end

function M.test:cpy(ut)
    local object = M
    local obj    = object "obj" { val1 = 1 }
    local cpy1   = ut:succeeds(obj.cpy, obj, "cpy1")
    ut:equals(cpy1.val1, 1)
    cpy1.val2 = 2
    local cpy2 = ut:succeeds(cpy1.cpy, cpy1, "cpy2")
    ut:equals(cpy2.val1, cpy1.val1)
    ut:equals(cpy2.val2, cpy1.val2)
    cpy1.val3 = 3
    ut:differs(cpy2.val3, cpy1.val3)
end

function M.test:get(ut)
    local object = M
    local obj1   = object "obj1" { val1 = 1 }
    local obj2   = obj1   "obj2" { val2 = 2 }
    ut:succeeds(obj2.set, obj2, "val3", 3)
    ut:equals(obj2:get("val3"), 3)
    ut:differs(obj1:get("val3"), 3)
    ut:succeeds(obj1.set, obj1, "val4", 4)
    ut:equals(obj2:get("val4"), 4)
    ut:equals(obj1:get("val4"), 4)
    ut:succeeds(obj1.set, obj1, { val5 = 5, val6 = 6 })
    local a1,b1 = ut:succeeds(obj1.get, obj1, { "val5", "val6" })
    local a2,b2 = ut:succeeds(obj2.get, obj2, { "val5", "val6" })
    ut:equals(a2, 5)
    ut:equals(a1, 5)
    ut:equals(b2, 6)
    ut:equals(b1, 6)
end

function M.test:set(ut)
    local object = M
    local obj1   = object "obj1" { val1 = 1 }
    local obj2   = obj1   "obj2" { val2 = 2 }
    ut:succeeds(obj2.set, obj2, "val3", 3)
    ut:equals(obj2.val3, 3)
    ut:differs(obj1.val3, 3)
    ut:succeeds(obj1.set, obj1, "val4", 4)
    ut:equals(obj2.val4, 4)
    ut:equals(obj1.val4, 4)
    ut:succeeds(obj1.set, obj1, { val5 = 5, val6 = 6 })
    ut:equals(obj2.val5, 5)
    ut:equals(obj1.val5, 5)
    ut:equals(obj2.val6, 6)
    ut:equals(obj1.val6, 6)
end

function M.test:unset(ut)
    local object = M
    local obj1   = object "obj1" { val1 = 1 }
    local obj2   = obj1   "obj2" { val2 = 2 }
    ut:succeeds(obj2.set, obj2, "val3", 3)
    ut:succeeds(obj1.set, obj1, "val4", 4)
    ut:succeeds(obj1.set, obj1, { val5 = 5, val6 = 6 })
    ut:succeeds(obj2.unset, obj2, "val3")
    ut:equals(obj2.val3, nil)
    ut:differs(obj1.val3, 3)
    ut:succeeds(obj1.unset, obj1, { "val4", "val5" })
    ut:equals(obj2.val4, nil)
    ut:equals(obj1.val4, nil)
    ut:equals(obj2.val5, nil)
    ut:equals(obj1.val5, nil)
    ut:succeeds(obj2.unset, obj2, "val6")
    ut:equals(obj2.val6, 6)
    ut:equals(obj1.val6, 6)
end

-- end -------------------------------------------------------------------------
return M
