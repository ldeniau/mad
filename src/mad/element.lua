local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.element -- build MAD element

SYNOPSIS
  elm = require"mad.element"
  drift, sbend, rbend, quad = elm.drift, elm.sbend, elm.rbend, elm.quadrupole
  mq = quad 'mq' {}
  qf = mq { k1= 0.1 } -- focusing quadrupole
  qd = mq { k1=-0.1 } -- defocusing quadrupole

DESCRIPTION
  The module mad.element is a front-end to the factory of all MAD elements.

RETURN VALUES
  The list of supported elements.

SEE ALSO
  mad.sequence, mad.beam, mad.object
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"

-- locals ----------------------------------------------------------------------

local type, setmetatable = type, setmetatable
local rawget, pairs = rawget, pairs
local is_list = object.is_list

-- metatable for the root class of all elements
local MT = object { name='meta_element' }

 -- root of all elements
M.element = MT { name='element', kind='element', is_element=true }

-- functions -------------------------------------------------------------------

-- transform elements to classes during first instanciation
local function init(self)
  if not rawget(self, 'name') then
    error("classes must be named")
  end
  if rawget(self, 'kind') then
    self['is_'..self.kind] = true   -- identification
  end
  self.__index  = self              -- inheritance
  self.__call   = MT.__call         -- constructor
  self.__mul    = MT.__mul          -- repetition
end

local special_fields = {  name=true,  s_pos=true,   i_pos=true,
                         __mul=true, __call=true, __index=true  }

local function show_list(t, list, sep)
  local a
  for _,v in ipairs(list) do
    a = t[v]
    if a then io.write(', ', v, sep, tostring(a)) end
  end
end

local function show_inheritance(self, depth, sep)
  for k,v in pairs(self) do
    if type(k) == 'number' then
      io.write(', ', tostring(v))
    elseif not special_fields[k] then
      io.write(', ', k, sep, tostring(v))
    end
  end
  if depth > 0 and not rawget(self:class(), 'kind') then
    show_inheritance(self:class(), depth-1)
  end
end

local function show_properties(self, disp, sep)
  disp = disp or 0
  if type(disp) == 'number' then
    show_inheritance(self, disp, sep)
  elseif is_list(disp) then
    show_list(self, disp, sep)
  else
    error("invalid show argument, depth level or list of fields expected")
  end
end

-- methods ---------------------------------------------------------------------

function MT:class() -- idem obj:spr() but more 'common' in MAD world
  return getmetatable(self)
end

function MT:is_class()
  return rawget(self, '__call') ~= nil
end

function MT:show(disp)
  io.write('  ', self:class().name, " '", self.name, "' { at= ", self.s_pos)
  show_properties(self, disp, '= ')
  io.write(' }\n')
end

function MT:show_madx(disp)
  io.write('  ', self.name, ': ', self:class().name, ',\t\t at:= ', self.s_pos)
  show_properties(self, disp, ':= ')
  io.write(';\n')
end

-- metamethods -----------------------------------------------------------------

-- constructor of elements, can be unamed (inherit its name)
function MT:__call(a)
  if type(a) == 'string' then   -- class 'name' { ... }
    return function(t)
      if is_list(t) then
        t.name = a
        if not self:is_class() then init(self) end
        return setmetatable(t, self)
      end
      error ("invalid constructor argument, list expected")
    end
  end

  if is_list(a) then    -- class { ... }
    if not self:is_class() then init(self) end
    return setmetatable(a, self)
  end

  error ("invalid constructor argument, string expected")
end

-- repetition
function MT.__mul(n, elem)
  if type(elem) == 'number' then n, elem = elem, n end
  return { _rep=n, elem } -- return a list
end

-- members ---------------------------------------------------------------------

-- element famillies
M.drift       = M.element     'drift'       { kind='drift' }
M.cavity      = M.element     'cavity'      { kind='cavity' }
M.magnet      = M.element     'magnet'      { kind='magnet' }
M.kicker      = M.element     'kicker'      { kind='kicker' }
M.marker      = M.element     'marker'      { kind='marker' }
M.patch       = M.element     'patch'       { kind='patch' }

-- drifts
M.monitor     = M.drift       'monitor'     { kind='monitor' }
M.collimator  = M.drift       'collimator'  { kind='collimator' }
M.placeholder = M.drift       'placeholder' { kind='placeholder' }

-- cavities
M.rfcavity    = M.cavity      'rfcavity'    { kind='rfcavity' }

-- magnets
M.sbend       = M.magnet      'sbend'       { kind='sbend' }
M.rbend       = M.magnet      'rbend'       { kind='rbend' }
M.quadrupole  = M.magnet      'quadrupole'  { kind='quadrupole' }
M.sextupole   = M.magnet      'sextupole'   { kind='sextupole' }
M.octupole    = M.magnet      'octupole'    { kind='octupole' }
M.decapole    = M.magnet      'decapole'    { kind='decapole' }
M.dodecapole  = M.magnet      'dodecapole'  { kind='dodecapole' }
M.multipole   = M.magnet      'multipole'   { kind='multipole' }
M.elseparator = M.magnet      'elseparator' { kind='elseparator' }
M.solenoid    = M.magnet      'solenoid'    { kind='solenoid' }

-- kickers
M.hkicker     = M.kicker      'hkicker'     { kind='hkicker' } 
M.vkicker     = M.kicker      'vkicker'     { kind='vkicker' } 
M.tkicker     = M.kicker      'tkicker'     { kind='tkicker' } 

-- collimators
M.rcollimator = M.collimator  'rcollimator' { kind='rcollimator' }

-- collimators
M.rcollimator = M.collimator 'rcollimator'  { kind='rcollimator' }

-- monitors
M.bpm         = M.monitor     'bpm'         { kind='bpm' }
M.blm         = M.monitor     'blm'         { kind='blm' }

-- others
M.instrument  = M.placeholder 'instrument'  { kind='instrument' }


-- end -------------------------------------------------------------------------
return M
