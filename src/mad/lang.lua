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


local currentKey

M.getParser = function (key)
	if not options then error("Options haven't been set for lang.lua") end
	if not parsers[key] then error("There's no parser mapped to key: "..key) end
	local p = parsers[key]()
	local parse = p.parse
	local modifiedParse = function(self, inputStream, fileName, pos)
		currentKey = key
		local startMem = collectgarbage("count")
		local ast = parse(self, inputStream, fileName, pos)
		print("memory used by creating AST: "..tostring((collectgarbage("count")-startMem)*1024).." B")
		if options.dumpAst then
			tableUtil.printTable(ast)
		end
		ast.fileName = fileName
		return ast
	end
	p.parse = modifiedParse
	return p
end

function M.getCurrentKey()
	return currentKey or "lua"
end

-- test -----------------------------------------------------------------------
function M.test:getParser(ut)
	ut:succeeds(M.getParser, "lua")
	ut:fails(M.getParser, "IGuessThereWillNeverBeALanguageWithThisKey")
end

function M.test:getCurrentKey(ut)
	ut:equals(M.getCurrentKey(),"lua")
	currentKey = "key"
	ut:equals(M.getCurrentKey(),"key")
	currentKey = nil
end

function M.test:self(ut)
    require"mad.core.unitTest".addModuleToTest("mad.lang.lua.parser")
end

-- end ------------------------------------------------------------------------
return M
