local M = { help={}, test={}, _author="Martin Valen", _year=2013 }

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
	return call(...)
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

M.help.call = [[
PARAMETERS
	ext: The extension of the language to be parsed.
	interactive: Whether one wants an interactive parser or not (batch mode). Defaults to batch mode.
RETURN VALUES
	The lpeg-compiled grammar.
]]
call = function (_, ext, interactive)
	local interactive = interactive or false
	return grammar[interactive][ext] or addGrammar(ext, interactive)
end

-- test -----------------------------------------------------------------------
M.test.self = function (...)
	--Create a batch grammar of mad
	local batchGramm = M("mad")
	
	--Create an interactive grammar of mad
	local intGramm = M("mad")
	
	--Matching mad-code
	local code = [[local a = 5]]
	local ast = batchGramm:match(code)
	
	--All tests passed
	return true
end


-- end ------------------------------------------------------------------------
return M
