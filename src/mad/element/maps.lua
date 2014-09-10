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

-- locals ----------------------------------------------------------------------

local cos, sin, cosh, sinh = math.cos, math.sin, math.cosh, math.sinh

-- functions -------------------------------------------------------------------

M.track_drift = function (L)
  -- handbook of accelerator physics 2.2.1
  return function (ray)
    ray.x = ray.x + L * ray.px
    ray.y = ray.y + L * ray.py
  end
end

M.track_thick_dipole = function (L, angle)
  return function (ray)
  end
end

M.track_thick_quadrupole = function (L, k)
  -- handbook of accelerator physics 2.2.1
  local C , S  = cos (k*L), sin (k*L)
  local Ch, Sh = cosh(k*L), sinh(k*L)
  local r11, r12 =    C, S/k
  local r21, r22 = -k*S, C
  local r33, r34 =   Ch, Sh/k
  local r43, r44 = k*Sh, Ch
  return  function (ray)
    ray. x = R11*ray.x + R12*ray.px
    ray.px = R21*ray.x + R22*ray.px
    ray. y = R33*ray.y + R34*ray.py
    ray.py = R43*ray.y + R44*ray.py
  end
end

M.track_thick_sextupole = function (L, k)
  return function (ray)
  end
end

-- test suite -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M
