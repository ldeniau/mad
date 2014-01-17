local M = { help={}, test={}, _author="LD", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad -- Methodical Accelerator Design package

SYNOPSIS
  local mad = require "mad"

DESCRIPTION
  The MAD package provides a common interface to all the modules and services
  required to run MAD.

RETURN VALUES
  The table of MAD modules and services.

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------

-- core
M.env      = require "mad.env"
M.helper   = require "mad.helper"
M.tester   = require "mad.tester"
M.module   = require "mad.module"
M.object   = require "mad.object"

-- layout
-- M.beam     = require "mad.beam"
-- M.element  = require "mad.element"
-- M.sequence = require "mad.sequence"

-- physics
-- M.math     = require "mad.math"
-- M.field    = require "mad.field"
-- M.optic    = require "mad.optic"
-- M.track    = require "mad.track"
-- M.survey   = require "mad.survey"

-- end -------------------------------------------------------------------------
return M
