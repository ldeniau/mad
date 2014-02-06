local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.lang.generator

SYNOPSIS
  local gen    = require"mad.lang.generator"
  local sourcegen = gen.getGenerator(key, errors, lambdatable)

DESCRIPTION
  Contains functions for getting the parsers corresponding to different languages.
  
  local sourcegen = gen.getGenerator(key, errors, lambdatable)
    -Returns the generator corresponding to key. errors and lambdatable are sent to
    the generators.

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
	mad = require"mad.lang.generator.mad",
}

M.getGenerator = function (key, errors, l)
	if not options then error("Options haven't been set for lang.generator") end
	if not generators[key] then error("There's no generator mapped to key: "..key) end
	return generators[key](errors, l)
end


-- test -----------------------------------------------------------------------


-- end ------------------------------------------------------------------------
return M
