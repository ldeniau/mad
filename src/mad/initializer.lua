local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.initializer -- Methodical Accelerator Design package

SYNOPSIS
  require "mad.initializer"

DESCRIPTION
  Runs all the modules that set up the mad environment

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
--M.require				= require "mad.initializer.require"
M.lambda   			= require "mad.initializer.lambda"

-- end -------------------------------------------------------------------------
return M
