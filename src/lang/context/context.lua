local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  context

SYNOPSIS
  local context = require"mad.lang.context".new()

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local util = require('lang.util')
local Scope = require"lang.context.scope"

-- module ---------------------------------------------------------------------

M.__index = M
function M.new()
	local self = {
		scope = Scope.new()
	}
	return setmetatable(self, M)
end
function M:enter()
	self.scope = Scope.new(self.scope)
end
function M:leave()
	self.scope = self.scope.outer
end
function M:define(name, info)
	info = info or { }
	self.scope:define(name, info)
	return info
end
function M:globalDefine(name, info)
	info = info or { }
	local s = self.scope
	while	s.outer do
		s = s.outer
	end
	s:define(name, info)
	return info
end
function M:lookup(name)
	local info = self.scope:lookup(name)
	return info
end


-- end ------------------------------------------------------------------------
return M
