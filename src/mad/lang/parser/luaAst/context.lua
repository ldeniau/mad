local M = { help={}, test={}, _author="Martin Valen and Richard Hundt", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  context

SYNOPSIS
  local context = require"mad.lang.parser.luaAst.context".new()

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local util = require('mad.lang.util')

-- module ---------------------------------------------------------------------

local Scope = { }
Scope.__index = Scope
function Scope.new(outer)
	local self = {
		outer = outer;
		entries = { };
	}
	return setmetatable(self, Scope)
end
function Scope:define(name, info)
	self.entries[name] = info
end
function Scope:lookup(name)
	if self.entries[name] then
		return self.entries[name]
	elseif self.outer then
		return self.outer:lookup(name)
	else
		return nil
	end
end

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
