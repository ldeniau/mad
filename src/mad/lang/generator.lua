local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.lang.generator

SYNOPSIS
  local lang   = require"mad.lang"
  local parser = lang.getParser(key, [line])
  local key    = lang.getCurrentKey()

DESCRIPTION
  Contains functions for getting the parsers corresponding to different languages.
  
  local parser = lang.getParser(key, [line])
    -Returns the parser corresponding to key. line is an optional argument to be
     given when parsing in interactive mode.
  local key    = lang.getCurrentKey()
    -Returns the key of the parser being used at the moment.

RETURN VALUES
  None

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local tableUtil = require"lua.tableUtil"
local options = require"mad.core.options"

-- module ---------------------------------------------------------------------
local generators = {
	lua = require"mad.lang.generator.lua",
	--mad = require"mad.lang.generator.mad",
}

M.getGenerator = function (key, errors, l)
	if not options then error("Options haven't been set for lang.generator") end
	if not generators[key] then error("There's no generator mapped to key: "..key) end
	return generators[key](errors, l)
end


-- test -----------------------------------------------------------------------


-- end ------------------------------------------------------------------------
return M
