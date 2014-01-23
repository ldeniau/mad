local M  = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad -- Methodical Accelerator Design package

SYNOPSIS
  local mad = require "mad"

DESCRIPTION
  The MAD package provides all the modules and services required to run MAD.

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- requires --------------------------------------------------------------------

M.env      = require "mad.env"
M.helper   = require "mad.helper"
M.tester   = require "mad.tester"

M.beam     = require "mad.beam"
M.element  = require "mad.element"
M.sequence = require "mad.sequence"

-- end -------------------------------------------------------------------------
return M
