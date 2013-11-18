local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  run

SYNOPSIS
  local run = require "run"

DESCRIPTION
  Contains functions to compile and run mad-files.

RETURN VALUES
	

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local util	  = require('mad.lang.util')
local source = require"mad.lang.source"
local preParser = require"mad.lang.preParserGenerator"
local postParser = require"mad.lang.parser.luaAst.postParser"

--  ----------------------------------------------------------------------

GLOBAL = setmetatable({
	assert  = function(...) return assert(...) end;
	print	= function(...) print(...) end;
}, { __index = _G })

function M.run(arg)
	local fullName = arg[1]
	if type(arg) == "table" then
		fileName, ext = util.getNamepathAndExtension(arg[1])
	end
	local istream = util.openFile(fullName)
	local newParser = preParser(ext)
	local code = M.compile(newParser, istream, fullName)
	return M.runLuaCode(code)
end

function M.createSource(preParser, inputStream, fileName)
	local start = os.clock()
	local ret = source.generate(postParser.transform(preParser:parse(inputStream, fileName)))
	local finish = os.clock()
	print("Elapsed Time:",finish-start)
	return ret
end

function M.compile(preParser, inputStream, fileName)
	return assert(loadstring(M.createSource(preParser, inputStream, fileName)))
end

function M.runLuaCode(code)
	local status, arguments = xpcall(code, debug.traceback)
	if status then
		return arguments
	else
		require"mad.lang.errorHandler":handleError(arguments)
	end
end



-- end --------------------------------------------------------------------------
return M
