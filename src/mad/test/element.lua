local M = {}

local seq, elem = nil
local rbend, sbend, quad, sext, drift = nil

function M:setUp()
  if seq then return end

	seq  = require"mad.sequence"
	elem = require"mad.element"

  rbend = elem.rbend
  sbend = elem.sbend
	quad  = elem.quadrupole
  sext  = elem.sextupole
	drift = elem.drift
end

function M:tearDown()
end

function M:sps_seq(ut)
  local qf = quad  'qf' { l=1 }
  local qd = quad  'qd' { l=1 }
  local b1 = rbend 'b1' { l=3 }
  local b2 = rbend 'b2' { l=3 }
  local ds = drift 'ds' { l=1 }
  local dm = drift 'dm' { l=2 }
  local dl = drift 'dl' { l=0.5 }

  local pf={qf,2*b1,2*b2,ds}
  local pd={qd,2*b2,2*b1,ds}

  local p24={qf,dm,2*b2,ds,pd}
  local p42={pf,qd,2*b2,dm,ds}

  local p00=seq{qf,dl,qd,dl}
  local p44=seq{pf,pd}

  local insert=seq 'insert' {p24,2*p00,p42}
  local super=seq 'super' {7*p44,insert,7*p44}
  local sps=seq 'sps' {6*super}

  -- TODO
end

-- end -------------------------------------------------------------------------
return M