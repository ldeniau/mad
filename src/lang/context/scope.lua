local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  scope

SYNOPSIS
  local scope = require"mad.lang.context.scope".new()

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local util = require('mad.lang.util')

-- module ---------------------------------------------------------------------

M.__index = M
function M.new(outer)
	local self = {
		outer = outer;
		entries = { };
	}
	return setmetatable(self, M)
end
function M:define(name, info)
	self.entries[name] = info
end
function M:lookup(name)
	if self.entries[name] then
		return self.entries[name]
	elseif self.outer then
		return self.outer:lookup(name)
	else
		return nil
	end
end

return M
