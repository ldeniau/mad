-- Should return the factory and keep track of all the different parsers.


local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  lang

SYNOPSIS
  

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local testApi = require"mad.test.api"

-- module ---------------------------------------------------------------------
local parsers = {
	lua = require"mad.lang.lua.parser",
	--mad = require"mad.lang.mad.parser",
}

M.getParser = function (key)
	if not parsers[key] then error("There's no parser mapped to key: "..key) end
	return parsers[key]()
end

-- test -----------------------------------------------------------------------
function M.test:getParser()
	testApi.succeeds(M.getParser, "lua")
	testApi.fails(M.getParser, "IGuessThereWillNeverBeALanguageWithThisKey")
end

-- end ------------------------------------------------------------------------
return M
