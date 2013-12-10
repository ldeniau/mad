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
local sourceCodeGenerator = require"mad.lang.generator.source"
local errorMap = require"mad.lang.errorMap"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

call = function (_, options)
	for _, fileName in ipairs(options.files) do
		local startTime = os.clock()
		local errorMap = errorMap()
		local gen = sourceCodeGenerator()
		local path, name, ext = fn.split(fileName)
		local file = assert(io.open(fileName, 'r'))
		local inputStream = file:read('*a')
		file:close()
		local parser = lang.getParser(ext)
		local source = gen:generate(parser:parse(inputStream, fileName))
		local loadedCode, err = loadstring(source,'@'..fileName)
		if loadedCode then
			local status, err = xpcall(loadedCode,debug.traceback)
			if not status then
				print("Error in xpcall:",err)
			end
		else
			print("Error in loadstring:",err)
		end
		local totalTime = os.clock() - startTime
		print(string.format("elapsed time: %.2fs", totalTime))
	end
end

-- end ------------------------------------------------------------------------
return M
