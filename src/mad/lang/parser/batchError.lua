local M = { help={}, test={}, _author="Martin Valen", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  error

SYNOPSIS
  local actionsBatchError = require"mad.lang.parser.actions.batchError".actions

DESCRIPTION
  Error handling for ast-building when working in batch mode

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ------------------------------------------------------------------
local util = require('mad.lang.util')
local env = require"mad.lang.environment"

local defs = {}

function defs.error(istream, pos)
	local loc = string.sub(istream, pos, pos)
	if loc == '' then
		error("Unexpected end of input while parsing file ")
	else
		local tok = string.match(istream, '(%w+)', pos) or loc
		local line = 0
		local ofs  = 0
		while ofs < pos do
			local a, b = string.find(istream, "\n", ofs)
			if a then
				ofs = a + 1
				line = line + 1
			else
				break
			end
		end
		error("Unexpected token '"..tok.."' on line "..tostring(line).." in file ")
	end
end

M.actions = defs

return M
