local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.element -- build element for reuse in sequences (database)

SYNOPSIS
  elm = require"mad.element"
  drift, sbend, rbend, quad = elm.drift, elm.sbend, elm.rbend, elm.quadrupole

DESCRIPTION
  The module mad.element is a front-end to the factory of all elements
  supported by MAD.

RETURN VALUES
  The table of supported elements.

SEE ALSO
  mad.sequence, mad.beam, mad.object
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"

-- locals ----------------------------------------------------------------------

local type, setmetatable = type, setmetatable
local rawget, pairs = rawget, pairs

-- metatable for the root class of all elements
local MT = object { name='meta_element' }

 -- root of all elements
M.element = MT { name='element', is_element=true, kind='element' }

-- functions -------------------------------------------------------------------

local function init(self)
  if not rawget(self, 'name') then
    error('classes must be named')
  end
  self.__index  = self              -- inheritance
  self.__call   = MT.__call         -- constructor
  self.__mul    = MT.__mul          -- repetition
end

local special_field = {  name=true, __mul=true, __call=true, __index=true }

local function print(self, nodisp)
  for k,v in pairs(self) do
    if type(k) == 'number' then
      io.write('[',k,']=', tostring(v), ', ')
    elseif not special_field[k] and not (nodisp and nodisp[k]) then
      io.write(k, '=', tostring(v), ', ')
    end
  end
end

-- methods ---------------------------------------------------------------------

function MT:class() -- same as obj:spr() but more 'common' on MAD element
  return getmetatable(self)
end

function MT:toclass()
  init(self)
  return self
end

function MT:is_class()
  return rawget(self, '__call') ~= nil
end

function MT:show(depth, nodisp)
  io.write("'", self.name, "' { ")
  print(self, nodisp)
  if depth and depth > 0 then
    self:class():show(depth-1)
  end
  io.write('class=', self:class().name, ' }, ')
end

-- metamethods -----------------------------------------------------------------

-- constructor of elements, can be anonymous
function MT:__call(a)
  if type(a) == 'string' then
    return function(t)
      if type(t) == 'table' then
        t.name = a
        if not self:is_class() then init(self) end
        return setmetatable(t, self)
      end
      error ("invalid constructor argument, table expected")
    end
  end

  if type(a) == 'table' then
    if not self:is_class() then init(self) end
    return setmetatable(a, self)
  end

  error ("invalid constructor argument, string expected")
end

-- repetition
function MT.__mul(n, elem)
  if type(elem) == 'number' then
    n, elem = elem, n
  end
  return { _rep=n<0 and -n or n, elem } -- return a list
end

-- members ---------------------------------------------------------------------

-- element famillies
M.drift       = M.element 'drift'       { kind='drift' }
M.magnet      = M.element 'magnet'      { kind='magnet' }
M.marker      = M.element 'marker'      { kind='marker' }
M.patch       = M.element 'patch'       { kind='patch' }

-- drifts
M.monitor     = M.drift   'monitor'     { kind='monitor' }
M.placeholder = M.drift   'placeholder' { kind='placeholder' }

-- magnets
M.sbend       = M.magnet  'sbend'       { kind='sbend' }
M.rbend       = M.magnet  'rbend'       { kind='rbend' }
M.quadrupole  = M.magnet  'quadrupole'  { kind='quadrupole' }
M.sextupole   = M.magnet  'sextupole'   { kind='sextupole' }
M.octupole    = M.magnet  'octupole'    { kind='octupole' }
M.decapole    = M.magnet  'decapole'    { kind='decapole' }
M.dodecapole  = M.magnet  'dodecapole'  { kind='dodecapole' }
M.elseparator = M.magnet  'elseparator' { kind='elseparator' }

-- monitors
M.bpm         = M.monitor 'bpm'         { kind='bpm' }
M.blm         = M.monitor 'blm'         { kind='blm' }

-- end -------------------------------------------------------------------------
return M
