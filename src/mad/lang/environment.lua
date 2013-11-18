local M  = { help = {}, _author = "MV", _year = 2013 }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad -- Methodical Accelerator Design package

SYNOPSIS
  local env = require "mad.lang.environment"

DESCRIPTION
  Contains the environment of the compiler

RETURN VALUES
  

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
local util = require"mad.lang.util"

-- modules ---------------------------------------------------------------------
local parser = {}

M.help.parser = [[Returns the current parser.]]
M.parser = function ()
	return parser[#parser]
end

M.help.pushParser = [[Sets the current parser.]]
M.pushParser = function (parser)
	parser[#parser+1] = parser
end

M.help.popParser = [[Pops the current parser.]]
M.popParser = function ()
	parser[#parser] = nil
end





-- end ---------------------------------------------------------------------
return M
