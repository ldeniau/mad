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

local insert_element = function (self, elem, pos)
  seq[i] = v              -- vector part
  k = rawget(v,'_id')

  if k then
    if type(seq[k]) == "table"
      seq[k]:insert(v)    -- dict part
    else
      seq[k] = v
    end
  end
end

local insert_sequence = function (self, seq, pos)
end

-- metamethods -----------------------------------------------------------------

S:__call = function (t) -- ctor
  local seq = S {}
  local i, k = 1

  for _,v in ipairs(t) do
    if super(v) == S then     -- insert sequence

    else                      -- insert element
      i = insert_element(seq, v, i)
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
