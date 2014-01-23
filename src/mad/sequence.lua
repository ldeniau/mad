local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

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

-- require ---------------------------------------------------------------------

local object = require"mad.object"
local super = object.super

local S = object "sequence" {}

-- methods ---------------------------------------------------------------------

local add_element = function (self, elem)
  self:insert(elem)                -- vector part

  local k = rawget(elem,'_id')     -- dict part
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

local add_sequence = function (self, seq)
  for _,v in ipairs(t) do
    add_element(self, v)
  end
end

-- metamethods -----------------------------------------------------------------

S:__call = function (t) -- ctor
  local seq = S {}

  for _,v in ipairs(t) do
    if super(v) == S then
      add_sequence(seq, v)
    else
      add_element(seq, v)
    end
  end

  return seq
end

-- repetition
S.__mul = function (a, b)
  error("TODO")
end

-- reflection
S.__unm = function (a, b)
  error("TODO")
end 

-- end -------------------------------------------------------------------------
return M
