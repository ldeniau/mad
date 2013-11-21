local M  = { help = {}, test = {}, _author = "MV", _year = 2013 }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad -- Methodical Accelerator Design package

SYNOPSIS
  local parser = require "mad.lang.parser"

DESCRIPTION
  

RETURN VALUES
  

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
local env = require"mad.lang.environment"
local util = require"mad.lang.util"
local grammar = require"mad.lang.parser.grammar"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local new
mt.__call = function (...)
	return new(...)
end

-- modules ---------------------------------------------------------------------

local parse = function (self, inputStream, fileName, pos)
	local position = pos or 1
	local push = false
	if self ~= env.parser() then
		env.pushParser(self)
		push = true
	end
	local ast = self.grammar:match(inputStream, position)
	ast.file = { name = fileName, inputStream = inputStream }
	if push then
		env.popParser()
	end
	return ast
end

local getInteractive = function (self)
	if not self.interactive then
		return M(self.ext, true)
	else
		return self
	end
end

local getBatch = function (self)
	if self.interactive then
		return M(self.ext, false)
	else
		return self
	end
end

M.help.new = [[
	Creates a parser to parse the language specified by the input ext.
	Returns the parser with the function parse(inputStream, fileName, [pos].
]]
new = function (_, ext, interactive)
	local self = {}
	self.ext = ext
	self.getInteractive = getInteractive
	self.getBatch = getBatch
	self.interactive = interactive or false
	self.parse = parse
	self.grammar = grammar(ext, interactive)
	return self
end


-- test -----------------------------------------------------------------------
M.test.self = function ()
	
end

-- end ------------------------------------------------------------------------

return M
