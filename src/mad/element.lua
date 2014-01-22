local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.element -- build element database for reuse in sequences

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

-- require ---------------------------------------------------------------------

local object = require"mad.object"

-- class of elements -----------------------------------------------------------

local E = object "element" {}

M.drift 		  = E "drift" 		  {}
M.sbend 		  = E "sbend" 		  {}
M.rbend 		  = E "rbend" 		  {}
M.quadrupole  = E "quadrupole"  {}
M.sextupole  	= E "sextupole"  	{}
M.octupole   	= E "octupole"   	{}
M.decapole  	= E "decapole"  	{}
M.dodecapole  = E "dodecapole"  {}

M.elseparator	= E "elseparator" {}

M.bpm   		  = E "bpm"   		  {}
M.blm   		  = E "blm"   		  {}

M.marker   		= E "marker"   		{}
M.placeholder	= E "placeholder" {}

-- metamethods -----------------------------------------------------------------

-- repetition
E.__mul = function (a, b)
  error("TODO")
end

-- reflection
E.__unm = function (a, b)
  error("TODO")
end 

-- end -------------------------------------------------------------------------
return M
