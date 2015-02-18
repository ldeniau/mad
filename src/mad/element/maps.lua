local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.element.maps -- build MAD element dynamical maps

SYNOPSIS
  maps = require"mad.element.maps"

DESCRIPTION
  The module mad.element.maps provides the slice maps used to build MAD elements.

RETURN VALUES
  The list of supported maps.

SEE ALSO
  mad.element
]]
 
-- requires --------------------------------------------------------------------

local elem = require"mad.element"

-- locals ----------------------------------------------------------------------

local cos, sin, cosh, sinh = math.cos, math.sin, math.cosh, math.sinh

-- functions -------------------------------------------------------------------

-- track maps

elem.drift.track = function (self, X)
  -- handbook of accelerator physics 2.2.1
  local L = self.L
  local Y = {}
  Y.x = X.x + L * X.px
  Y.y = X.y + L * X.py
  return Y
end

elem.dipole.track = function (self, X)
  local L, angle = self.L, self.angle
  local Y = {}
  -- todo
  return Y
end

elem.quadrupole.track = function (self, X)
  -- handbook of accelerator physics 2.2.1
  local L, k = self.L, self.k1
  local C  ,  S  = cos (k*L), sin (k*L)
  local Ch ,  Sh = cosh(k*L), sinh(k*L)
  local r11, r12 =    C, S/k
  local r21, r22 = -k*S, C
  local r33, r34 =   Ch, Sh/k
  local r43, r44 = k*Sh, Ch

  -- todo QD
  local Y = {}
  Y. x = r11*X.x + r12*X.px
  Y.px = r21*X.x + r22*X.px
  Y. y = r33*X.y + r34*X.py
  Y.py = r43*X.y + r44*X.py
  return Y
end

elem.sextupole.track = function (self, X)
  -- handbook of accelerator physics 2.2.1
  local L, k = self.L, self.k2
  local Y = {}
  -- todo
  return Y
end

-- test suite -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M
