local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.lang.generator

SYNOPSIS
  local gen       = require'mad.lang.generator'
  local sourcegen = gen.getGenerator(key, errors, lambdatable)

DESCRIPTION
  Contains functions for getting the generators corresponding to different languages.
  
  gen.getGenerator(key, errors, lambdatable)
    Returns the generator corresponding to key. errors and lambdatable are sent to
    the generators.

RETURN VALUES
  A table with the getGenerator function

SEE ALSO
  mad.lang.generator.lua
  mad.lang.generator.mad
]]

-- require --------------------------------------------------------------------
local tableUtil = require"lua.tableUtil"
local options = require"mad.core.options"

-- module ---------------------------------------------------------------------
local generators = {
	lua = require"mad.lang.generator.lua",
	mad = require"mad.lang.generator.mad",
}

M.getGenerator = function (key, errors, lambdaTable)
	if not options then error("Options haven't been set for lang.generator") end
	if not generators[key] then error("There's no generator mapped to key: "..key) end
	return generators[key](errors, lambdaTable)
end


-- test -----------------------------------------------------------------------
function M.test:setUp()
    self.errors = require"mad.lang.errors"()
end

function M.test:tearDown()
    self.errors = nil
end

function M.test.self(ut)
    require"mad.tester".addModuleToTest"mad.lang.generator.lua"
    require"mad.tester".addModuleToTest"mad.lang.generator.mad"
end

function M.test:getGenerator(ut)
    ut:succeeds(M.getGenerator, 'lua', self.errors)
    ut:succeeds(M.getGenerator, 'mad', self.errors)
    ut:fails(M.getGenerator, 'IGuessThereWillNeverBeAGeneratorWithThisKey', self.errors)
end

-- end ------------------------------------------------------------------------
return M
