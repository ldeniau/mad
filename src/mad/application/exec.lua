local M = { help = {}, test = {}, _author = "Martin Valen", _year = 2013 }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local fileHandler = require"mad.application.util.fileHandler"
local parserFactory = require"mad.lang.parser.parserFactory"
local postParser = require"mad.lang.parser.luaAst.postParser"
local source = require"mad.lang.generator.source"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------




call = function (_, fileName)
	local path, name, ext = fileHandler.getPathNameExtension(fileName)
	local inputStream = fileHandler.getInputStream(fileName)
	local preParser = parserFactory.getParser(ext)
	local postParser = postParser()
	local source = source()
	assert(loadstring(source:generate(postParser:transform(preParser:parse(inputStream, fileName))) ,name))()
end

-- end ------------------------------------------------------------------------
return M
