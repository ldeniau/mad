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
  inherits all properties of it automatically, hence implementing a prototype
  language.

  Hence an object is a 'table' that can be used as a constructor (a function)
  to create new instances of itself, an object (a table) or a class/parent
  (a metatable).

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
    self.object = require"mad.object"
end

function M.test:tearDown()
    self.object = nil
end

function M.test:spr(ut)
    local object = self.object
    local par1 = ut:succeeds(object, {})
    local par1spr = ut:succeeds(par1.spr, par1)
    ut:equals(par1spr, object)
    local par2 = ut:succeeds(par1, {})
    local par2spr = ut:succeeds(par2.spr, par2)
    ut:equals(par2spr, par1)
end

function M.test:isa(ut)
    local object = self.object
    local par1 = object {  }
    local is = ut:succeeds(par1.isa, par1, object)
    ut:equals(is, object)
    is = ut:succeeds(par1.isa, par1, 1)
    ut:equals(is, nil)
    is = ut:succeeds(par1.isa, par1)
    ut:equals(is, nil)
    local par21 = par1 {}
    local par22 = par1 {}
    is = ut:succeeds(par21.isa, par21, object)
    ut:equals(is, object)
    is = ut:succeeds(par21.isa, par21, par1)
    ut:equals(is, par1)
    is = ut:succeeds(par22.isa, par22, object)
    ut:equals(is, object)
    is = ut:succeeds(par22.isa, par22, par1)
    ut:equals(is, par1)
    is = ut:succeeds(par22.isa, par22, par21)
    ut:equals(is, nil)
    is = ut:succeeds(par21.isa, par21, par22)
    ut:equals(is, nil)
end

function M.test:ctor(ut)
    local object = self.object
    local obj1 = ut:succeeds(object, {})
    ut:fails(object)
    ut:fails(object, 1)
    ut:fails(object, 1, {})
    ut:fails(object, "hiojo")
    local obj11 = ut:succeeds(obj1, { val1 = 1 })
    local obj12 = ut:succeeds(obj1, {})
    ut:equals(obj11.val1, 1)
    ut:equals(obj12.val1, nil)
    ut:equals(obj1.val1, nil)
    obj1.val3 = 3
    ut:equals(obj1.val3, 3)
    ut:equals(obj12.val3, obj1.val3)
    ut:equals(obj11.val3, obj1.val3)
end

function M.test:cpy(ut)
    local object = self.object
    local obj    = object { val1 = 1 }
    local cpy1   = ut:succeeds(obj.cpy, obj)
    ut:equals(cpy1.val1, 1)
    cpy1.val2 = 2
    ut:equals(cpy1.val2, 2)
    ut:equals(obj.val2, nil)
    local cpy2 = ut:succeeds(cpy1.cpy, cpy1)
    ut:equals(cpy2.val1, cpy1.val1)
    ut:equals(cpy2.val2, cpy1.val2)
    cpy1.val3 = 3
    ut:differs(cpy2.val3, cpy1.val3)
end

function M.test:set(ut)
    local object  = self.object
    local obj1    = object { val1 = 1 }
    local obj11   = obj1   { val2 = 2 }
    local obj12   = obj1   {  }
    ut:succeeds(obj11.set, obj11, { val3 = 3 })
    ut:succeeds(obj11.set, obj11, { val5 = 5 })
    ut:succeeds(obj12.set, obj12, { val4 = 4 })
    ut:succeeds(obj12.set, obj12, { val6 = 6 })
    ut:equals(obj1.val1, 1)
    ut:equals(obj1.val2, nil)
    ut:equals(obj1.val3, nil)
    ut:equals(obj1.val4, nil)
    ut:equals(obj1.val5, nil)
    ut:equals(obj1.val6, nil)
    ut:equals(obj11.val1, 1)
    ut:equals(obj11.val2, 2)
    ut:equals(obj11.val3, 3)
    ut:equals(obj11.val4, nil)
    ut:equals(obj11.val5, 5)
    ut:equals(obj11.val6, nil)
    ut:equals(obj12.val1, 1)
    ut:equals(obj12.val2, nil)
    ut:equals(obj12.val3, nil)
    ut:equals(obj12.val4, 4)
    ut:equals(obj12.val5, nil)
    ut:equals(obj12.val6, 6)
    ut:fails(obj1.set,obj1,1)
    ut:fails(obj11.set,obj11,1)
    ut:fails(obj12.set,obj12,1)
    ut:fails(obj1.set,obj1)
    ut:fails(obj11.set,obj11)
    ut:fails(obj12.set,obj12)
end


-- end -------------------------------------------------------------------------
return M
