local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  grammarMad

SYNOPSIS
  local grammarMad = require"mad.lang.parser.grammarMad"

DESCRIPTION
  Returns the lpeg-compiled grammar of mad

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
local util = require('mad.lang.util')

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local new
mt.__call = function (...)
	return new(...)
end

-- grammar ---------------------------------------------------------------------
local grammar = {}
grammar[false] = {}
grammar[true] = {}

local function addGrammar(ext, interactive)
	local interactive = interactive or false
	local fileName = "mad.lang.parser.grammar."..ext
	local errorModule
	if interactive then
		errorModule = require"mad.lang.parser.actions.interactiveError"
	else
		errorModule = require"mad.lang.parser.actions.batchError"
	end
	grammar[interactive][ext] = require(fileName).grammar(errorModule.actions)
	return grammar[interactive][ext]
end

new = function (modSelf, ext, interactive)
	local interactive = interactive or false
	return grammar[interactive][ext] or addGrammar(ext, interactive)
end


-- end ------------------------------------------------------------------------
return M
