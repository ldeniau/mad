local M = {}

local seq, elem
local rb, mb, mq, dr

function M:setUp()
	seq  = require"mad.sequence"
	elem = require"mad.element"

  rb = elem.rbend
  mb = elem.sbend
	mq = elem.quadrupole
	dr = elem.drift
end

function M:tearDown()
end

-- end -------------------------------------------------------------------------
return M