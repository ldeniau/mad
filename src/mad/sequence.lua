local M  = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.sequence -- build sequences

SYNOPSIS
  seq = require"mad.sequence"
  elm = require"mad.element"
  MB, MQ = elm.sbend, elm.quadrupole
  my_seq = seq {
    MQ 'QF' {}, MB 'MB' {},
    MQ 'QD' {}, MB 'MB' {},
  }

DESCRIPTION
  The module mad.element is a front-end to the factory of all physcial elements
  supported by MAD.

RETURN VALUES
  The table of supported elements.

SEE ALSO
  mad.sequence, mad.beam, mad.object
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local drift  = require"mad.element".drift

M = object 'sequence' M -- make the module an object

-- locals ----------------------------------------------------------------------

local type, rawget, rawset, ipairs, pairs = type, rawget, rawset, ipairs, pairs

-- functions -------------------------------------------------------------------

local function add_element(self, elem_)
  local elem = elem_:cpy()
  self:insert(elem)                -- vector part

  local k = rawget(elem,'name')    -- dict part
  if k then
    local ref = rawget(self, k)
    if type(ref) == "table" then
      ref:insert(elem)
    else
      self[k] = {ref, elem}
    end
  else
    self[k] = elem
  end
end

local function add_sequence(self, seq)
  for _,v in ipairs(t) do
    add_element(self, v
  end
end

local function add_last_drift(self, ds)
  add_element(self, drift '' { length = ds })
  self.length = self.length + ds
end

-- methods ---------------------------------------------------------------------

-- M:new is inherited

function M:set(t)
  if type(t) ~= 'table' then
    error("invalid sequence description")
  end

  for _,v in ipairs(t) do
    if super(v) == M then
      add_sequence(self, v)
    else
      add_element(self, v)
    end
  end

  self.length = get_sequence_length(self)
  self.refer  = t.refer

  if t.length ~= nil and t.length > self.length then
    add_last_drift(self, t.length-self.length)
  end

  return self
end

-- metamethods -----------------------------------------------------------------

-- M:__call is inherited

-- repetition
function M.__mul(a, b)
  error("TODO")
end

-- reflection
function M.__unm(a, b)
  error("TODO")
end 

-- end -------------------------------------------------------------------------
return M
