local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.exec
DESCRIPTION
	contains functions for executing a file
]]

-- require --------------------------------------------------------------------
local fn = require"mad.core.fileName"
local lang = require"mad.lang"
local tableUtil = require"lua.tableUtil"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------




call = function (_, options)
	for _, fileName in ipairs(options.files) do
		local path, name, ext = fn.split(fileName)
		local file = assert(io.open(fileName, 'r'))
		local inputStream = file:read('*a')
		file:close()
		local parser = lang.getParser(ext)
		local ast = parser:parse(inputStream, fileName)
		if options.dumpAst then
			tableUtil.printTable(ast)
		end
	end
end

-- end ------------------------------------------------------------------------
return M
