local M = { help={}, test={}, name='object' }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.object -- creates objects

SYNOPSIS
  object = require"mad.object"
  obj = object 'name'           -- create a new object
  obj { ... }                   -- set obj values
  obj = object 'name' { ... }   -- create and set obj in one shot

DESCRIPTION
  The module mad.object creates new objects that are instances of their parent,
  with callable semantic.
  
  The returned object has its parent (its constructor) set as metatable and
  inherits all properties of it autmatically, hence implementing a prototype
  language.

  Hence an object is a 'table' that can be used as a constructor (a function)
  to create new instances, an object (a table) or a class/parent (a metatable).

  The string argument is stored into the property 'name' of the object.

RETURN VALUES
  The new object

ERRORS
  If the object does not receive a string (used as constructor) or a table (used
  as set), an invalid argument error is raised.

EXAMPLES
  object = require "mad.object"
  obj = object 'a' { flg = true }       -- name = 'a', flg = true
  obj { flg = false }                   -- set flg
  obj.flg = false                       -- set flg (fast)
  flg = obj.flg                         -- get flg (fast)
  obj2 = object obj.name (obj)          -- copy of obj, assume object is parent
  obj3 = obj:super() obj.name (obj)     -- copy of obj, don't know parent
  obj4 = obj:cpy()                      -- copy of obj, idem but faster

SEE ALSO
  mad.module, mad.element, mad.sequence, mad.beam
]]

-- locals ----------------------------------------------------------------------

local type, rawget, rawset, pairs = type, rawget, rawset, pairs
local getmetatable, setmetatable = getmetatable, setmetatable

local MT = {}; setmetatable(M, MT) -- make this module the root of all objects

-- methods ---------------------------------------------------------------------

-- return the direct parent
function M:super()
  return getmetatable(self)
end

-- return the parent id or nil
function M:isa(id)
  local a = getmetatable(self);

  if type(id) == 'table' then
    while a ~= nil and a ~= id do a = getmetatable(a) end
    return a

  elseif type(id) == 'string' then
    while a ~= nil and rawget(a, 'name') ~= id do a = getmetatable(a) end
    return a
  end

  error("invalid parent id, should be either an object or a name")
end

function M:cpy()
  local c = setmetatable({}, getmetatable(self))
  for k,v in pairs(self) do c[k] = v end
  return c
end

-- metamethods -----------------------------------------------------------------

-- object used as a function
function MT:__call(a)
  if type(a) == 'string' then
    if not rawget(self, '__call') then
      rawset(self, '__index', self)         -- inheritance
      rawset(self, '__call' , MT.__call)    -- call
    end
    return rawset(setmetatable({}, self), 'name', a)
  end

  if type(a) == 'table' then
    for k,v in pairs(a) do self[k] = v end
    return self
  end

  error ("invalid ".. self.name .." (implicit) call argument, string or table expected")
end

-- tests -----------------------------------------------------------------------

function M.test:setUp()
end

function M.test:tearDown()
end

function M.test:super(ut)
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

function M.test:new(ut)
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
