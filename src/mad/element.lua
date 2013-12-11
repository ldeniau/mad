local M  = { help = {}, _id = "mad", _author = "Laurent Deniau", _year = 2013 }

-- MAD -------------------------------------------------------------------------

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

-- modules ---------------------------------------------------------------------

M.env      = require "mad.env"
M.helper   = require "mad.helper"
M.tester   = require "mad.tester"

M.beam     = require "mad.beam"
M.element  = require "mad.element"
M.sequence = require "mad.sequence"

-- end -------------------------------------------------------------------------

return M
