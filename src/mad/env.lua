local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  env -- database for MAD environment

SYNOPSIS
  local env = require "mad.env"
  local log_level = env.option.log_level

DESCRIPTION
  The env module manages the database of the MAD environment.

RETURN VALUES
  The module.

SEE ALSO
  None
]]

-- end -------------------------------------------------------------------------
return M