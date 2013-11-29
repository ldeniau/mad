local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local fileHandler = require"core.fileHandler"
local parserFactory = require"lang.parser.parserFactory"
local util = require"lang.util"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------




call = function (_, options)
	for _, fileName in ipairs(options.files) do
		local path, name, ext = fileHandler.splitFileName(fileName)
		require("lang.parser."..ext..".init")
		local inputStream = fileHandler.getInputStream(fileName)
		local parser = parserFactory.getParser(ext)
		local ast = parser:parse(inputStream, fileName)
		options.dumpAst and	util.printTable(ast)
	end
end

-- end ------------------------------------------------------------------------
return M
