local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  luaBase

SYNOPSIS
  local defsLuaBase = require"mad.compiler.parser.defs.luaBase".defs

DESCRIPTION
  Returns the actions used by pattern.luaBase

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- defs ---------------------------------------------------------------------

local defs = {}

defs.tonumber = function(s)
	local n = string.gsub(s, '_', '')
	return tonumber(n)
end
defs.tostring = tostring
function defs.quote(s)
	return string.format("%q", s)
end
function defs.bcomm(pos,comm)
	return { type = "MultiLineComment", pos = pos, comment = comm}
end
function defs.lcomm(pos,comm)
	return { type = "SingleLineComment", pos = pos, comment = comm}
end

local strEscape = {
	["\\r"] = "\r",
	["\\n"] = "\n",
	["\\t"] = "\t",
	["\\\\"] = "\\",
}
function defs.string(str)
	return string.gsub(str, "(\\[rnt\\])", strEscape)
end
function defs.literal(val)
	return { type = "Literal", value = val }
end
function defs.boolean(val)
	return val == 'true'
end
function defs.nilExpr()
	return { type = "Literal", value = nil }
end
function defs.identifier(name)
	return { type = "Identifier", name = name }
end

M.defs = defs

return M
