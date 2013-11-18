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
	env.pushParser(self)
	local ast = self.grammar:match(inputStream, position)
	ast.file = { name = fileName, inputStream = inputStream }
	env.popParser()
	return ast
end

M.help.new = [[
	Creates a parser to parse the language specified by the input ext.
	Returns the parser with the function parse(inputStream, fileName, [pos].
]]
new = function (modSelf, ext, interactive)
	local self = {}
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
