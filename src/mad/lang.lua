-- Should return the factory and keep track of all the different parsers.


local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  lang

SYNOPSIS
  

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------

-- module ---------------------------------------------------------------------
local parsers = {
	lua = require"mad.lang.lua.parser",
	--mad = require"mad.lang.mad.parser",
}

M.getParser = function (key)
	return parsers[key]()
end


-- end ------------------------------------------------------------------------
return M
