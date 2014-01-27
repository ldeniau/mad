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
local errors = require"mad.lang.errors"()

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

call = function (_, options)
	for _, fileName in ipairs(options.files) do
		errors:setCurrentChunkName(fileName)
		local startTime = os.clock()
		local gen = sourceCodeGenerator(errors)
		local path, name, ext = fn.split(fileName)
		local file = assert(io.open(fileName, 'r'))
		local inputStream = file:read('*a')
		file:close()
		local parser = lang.getParser(ext)
		local source = gen:generate(parser:parse(inputStream, fileName))
		local loadedCode, err = loadstring(source,'@'..fileName)
		if loadedCode then
			local status, result = xpcall(loadedCode, function(_err)
				err = _err
				trace = debug.traceback("",2)
            end)
			if not status then
				io.stderr:write(errors:handleError(err,trace).."\n")
				os.exit(-1)
			end
		else
			error(err)
		end
		local totalTime = os.clock() - startTime
		print(string.format("elapsed time: %.2fs", totalTime))
	end
	if options.interactive then
	    require"mad.lang.interactive".interactive(errors)
	end
end

-- end ------------------------------------------------------------------------
return M
