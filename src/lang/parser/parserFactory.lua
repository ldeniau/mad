local M = { help={}, test={}, _author="Martin Valen", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  parserFactory

SYNOPSIS
  

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------

-- module ---------------------------------------------------------------------
local parsers = {}

M.registerParser = function (ext, parserCtr)
	parsers[ext] = parserCtr
end

M.getParser = function (ext)
	return parsers[ext]()
end


-- end ------------------------------------------------------------------------
return M
