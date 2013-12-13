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
local tableUtil = require"lua.tableUtil"
local options = require"mad.core.options"

-- module ---------------------------------------------------------------------
local parsers = {
	lua = require"mad.lang.lua.parser",
	--mad = require"mad.lang.mad.parser",
}

M.getParser = function (key)
	if not options then error("Options haven't been set for lang.lua") end
	if not parsers[key] then error("There's no parser mapped to key: "..key) end
	local p = parsers[key]()
	local parse = p.parse
	local modifiedParse = function(self, inputStream, fileName, pos)
		local ast = parse(self, inputStream, fileName, pos)
		if options.dumpAst then
			tableUtil.printTable(ast)
		end
		ast.fileName = fileName
		return ast
	end
	p.parse = modifiedParse
	return p
end

-- test -----------------------------------------------------------------------
function M.test:getParser(ut)
	ut:succeeds(M.getParser, "lua")
	ut:fails(M.getParser, "IGuessThereWillNeverBeALanguageWithThisKey")
end

-- end ------------------------------------------------------------------------
return M
