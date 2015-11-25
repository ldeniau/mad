local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.survey -- build MAD element geometrical maps and survey command

SYNOPSIS
  survey = require"mad.survey"

DESCRIPTION
  The module mad.survey provides...

RETURN VALUES
  The survey command

SEE ALSO
  mad.element
]]
 
-- requires --------------------------------------------------------------------

local E = require"mad.element"
local T = require"mad.table"
local U = require"mad.utils"

-- locals ----------------------------------------------------------------------

local getval = U.getval
local cos, sin, atan2 = math.cos, math.sin, math.atan2
local sqrt, floor, ceil = math.sqrt, math.floor, math.ceil
local twopi = 2*math.pi 

-- functions -------------------------------------------------------------------

-- helpers

local function vec (x, y, z)
  return { x, y, z }
end

local function unvec(v)
  return v[1], v[2], v[3]
end

local function mat (v1, v2, v3)
  return vec( v1, v2, v3 )
end

local function umat ()
  return vec( vec(1,0,0), vec(0,1,0), vec(0,0,1) )
end

local function vadd (a, b)
  return vec( a[1]+b[1], a[2]+b[2], a[3]+b[3] )
end

local function vdot (a, b)
  return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

local function mtrn (a)
  return mat(
    vec( a[1][1], a[2][1], a[3][1] ),
    vec( a[1][2], a[2][2], a[3][2] ),
    vec( a[1][3], a[2][3], a[3][3] )
  )
end

local function mmulv (a, b)
  return vec( vdot(a[1],b), vdot(a[2],b), vdot(a[3],b) )
end

local function mmul (a, b_)
  local b = mtrn(b_)
  return mat(
      vec( vdot(a[1],b[1]), vdot(a[1],b[2]), vdot(a[1],b[3]) ),
      vec( vdot(a[2],b[1]), vdot(a[2],b[2]), vdot(a[2],b[3]) ),
      vec( vdot(a[3],b[1]), vdot(a[3],b[2]), vdot(a[3],b[3]) )
    )
end

local function mrots(theta, phi, psi)
  local R, C, S

  if theta then
    C, S = cos(theta), sin(theta)
    R = mat( vec(C,0,S), vec(0,1,0), vec(-S,0,C) )
  else
    R = umat()
  end

  if phi then
    C, S = cos(phi), sin(phi)
    R = mmul(R, mat( vec(1,0,0), vec(0,C,S), vec(0,-S,C) ))
  end

  if psi then
    C, S = cos(psi), sin(psi)
    R = mmul(R, mat( vec(C,-S,0), vec(S,C,0), vec(0,0,1) ))
  end

  return R
end

local function rint(a)
  return a>0 and floor(a+0.5) or ceil(a-0.5)
end

local function rangle(a, ref)
  return a+twopi*rint((ref-a)/twopi)
end

local function mangles(m, theta, phi, psi)
  local arg = sqrt( m[2][1]*m[2][1] + m[2][2]*m[2][2] )
  local theta = rangle( atan2( m[1][3], m[3][3] ), theta )
  local phi   =         atan2( m[2][3], arg     )
  local psi   = rangle( atan2( m[2][1], m[2][2] ), psi   )
  return theta, phi, psi
end

-- load survey maps into elements

local survey_drift = function (X, L)
  local R = vec(0,0,L)
  X.V = vadd( mmulv(X.W, R), X.V )
end

E.element.survey = function (self, X)
  local L = getval(self.length)
  if L > 0 then
      survey_drift(X, L)
  end
  return self.s_pos + L
end

E.multipole.survey = function (self, X)
  local angle = self.knl and self.knl[1] or 0
  if angle == 0 then
    return self.s_pos
  end

  local ca, sa = cos(angle), sin(angle)
  local R = vec(0, 0, 0)
  local S = mat( vec(ca,  0, -sa),
                 vec( 0,  1,   0),
                 vec(sa,  0,  ca) )

  local tilt = self.tilt or 0
  if tilt ~= 0 then
    local ct, st = cos(tilt), sin(tilt)
    local T = mat( vec(ct,-st,0), vec(st,ct,0), vec(0,0,1) )
    R, S = mmulv(T,R), mmul(mmul(T,S),mtrn(T))
  end

  X.V = vadd( mmulv(X.W, R), X.V )
  X.W = mmul( X.W, S )

  return self.s_pos
end

E.sbend.survey = function (self, X)
  local angle = self.angle or 0
  if angle == 0 then
    return E.element.survey(self, X)
  end

  local L = self.length
  if L > 0 then
    local ca, sa = cos(angle), sin(angle)
    local rho = L/angle
    local R = vec(rho*(ca-1), 0, rho*sa)
    local S = mat( vec(ca,  0, -sa),
                   vec( 0,  1,   0),
                   vec(sa,  0,  ca) )

    local tilt = self.tilt or 0
    if tilt ~= 0 then
      local ct, st = cos(tilt), sin(tilt)
      local T = mat( vec(ct,-st,0), vec(st,ct,0), vec(0,0,1) )
      R, S = mmulv(T,R), mmul(mmul(T,S),mtrn(T))
    end

    X.V = vadd( mmulv(X.W, R), X.V )
    X.W = mmul( X.W, S )
  end

  return self.s_pos + L
end

-- survey table

M.table = function (name)
  name = name or 'survey'
  local tbl = T(name) ({{'name'}, 's', 'length', 'angle', 'tilt', 'X', 'Y', 'Z', 'theta', 'phi', 'psi', 'globaltilt'})
  tbl:set_key{ type='survey' }
  return tbl
end

-- survey command
-- survey { seq=seqname, tbl=tblname, X={x0,y0,z0}, A={theta0,phi0,psi0} }

M.survey = function (info)
  local seq = info.seq or error("invalid sequence")
  local tbl = M.table(info.tbl)

  local X = { V = info.X0 or vec(0,0,0), W = info.A0 and mrots(unvec(info.A0)) or umat() }

  local x, y, z
  local theta, phi, psi

  if info.A0 then theta, phi, psi = unvec(infoA0)
  else            theta, phi, psi = 0,0,0 end

  -- geometrical tracking
  local end_pos = seq[1].s_pos + seq[1].length -- $start marker
  for i=1,#seq do
    local e = seq[i]
    local ds = e.s_pos - end_pos

    -- implicit drift with L = ds
    if ds > 1e-6 then
      survey_drift(X, ds)
      end_pos = end_pos + ds
    end

    -- sequence element
    end_pos = e:survey(X)

    -- retieve columns values
    x, y, z = unvec(X.V)
    theta, phi, psi = mangles(X.W, theta, phi, psi)

    -- fill the table
    tbl = tbl + { name=e.name, s=e.s_pos,
                  length=e.length, angle=e.angle or (e.knl and e.knl[1]) or 0, tilt=e.tilt or 0,
                  X=x, Y=y, Z=z, theta=theta, phi=phi, psi=psi, globaltilt=(e.tilt or 0)+psi }
  end
  return tbl
end

-- test suite -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M
