local M = { help={}, test={}, _author="Martin Valen", _year=2013 }

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
local source = require"mad.lang.source"()
local preParser = require"mad.lang.preParserGenerator"
local postParser = require"mad.lang.parser.luaAst.postParser"()

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local new
mt.__call = function (...)
	return new(...)
end

-- module ---------------------------------------------------------------------

GLOBAL = setmetatable({
	assert  = function(...) return assert(...) end;
	print	= function(...) print(...) end;
}, { __index = _G })


M.help.run = [[
NAME
	run:run(fileName)
ARGUMENTS
	Filename to be run
SYNOPSIS
	Compiles and runs a file.
RETURN VALUES
	The return values of the code that's been run
]]
local function run(self, fullName)
	local fileName, ext = util.getNamepathAndExtension(fullName)
	local istream = util.openFile(fullName)
	local newParser = preParser(ext)
	local code = self:compile(newParser, istream, fullName)
	return self:runLuaCode(code)
end

M.help.createSource = [[
NAME
	run:createSource(preParser, inputStream, fileName)
ARGUMENTS
	preParser: The parser used to parse the inputStream
	inputStream: The code to be parsed
	fileName: Name of the file
SYNOPSIS
	Compiles the inputstream and creates lua source-code.
RETURN VALUES
	Translated Lua source code
]]
local function createSource(self, preParser, inputStream, fileName)
	local ret = source:generate(postParser:transform(preParser:parse(inputStream, fileName)), self.errorHandler)
	return ret
end

M.help.compile = [[
NAME
	run:compile(preParser, inputStream, fileName)
ARGUMENTS
	preParser: The parser used to parse the inputStream
	inputStream: The code to be parsed
	fileName: Name of the file
SYNOPSIS
	Compiles the inputstream, creates lua source-code and loads said code.
RETURN VALUES
	Loaded lua source code, ready to be run.
]]
local function compile(self, preParser, inputStream, fileName)
	return assert(loadstring(self:createSource(preParser, inputStream, fileName), fileName))
end

M.help.runLuaCode = [[
NAME
	run:run(code)
ARGUMENTS
	code: Loaded lua code
SYNOPSIS
	Runs lua code and gives 
RETURN VALUES
	The return values of the code that's been run
]]
local function runLuaCode(self, code)
	local status, arguments = xpcall(code, debug.traceback)
	if status then
		return arguments
	else
		self.errorHandler:handleError(arguments)
	end
end

new = function (_, ...)
	local self = {
		run = run,
		createSource = createSource,
		compile = compile,
		runLuaCode = runLuaCode,
		errorHandler = require"mad.lang.errorHandler"()
	}
	return self
end



-- end --------------------------------------------------------------------------
return M
