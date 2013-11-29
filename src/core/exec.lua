local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local fileHandler = require"core.splitFileName"
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
		local file = assert(io.open(fileName, 'r'))
		local inputStream = file:read('*a')
		file:close()
		local parser = parserFactory.getParser(ext)
		local ast = parser:parse(inputStream, fileName)
		if options.dumpAst then
			util.printTable(ast)
		end
	end
end

-- end ------------------------------------------------------------------------
return M
