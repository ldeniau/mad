local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.core.exec
	
SYNOPSIS
  require"mad.core.exec"(options)

DESCRIPTION
  Runs the files contained in the options, and enters interactive mode if that option is set.  

RETURN VALUES
  None

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local fn = require"mad.core.fileName"
local lang = require"mad.lang"
local tableUtil = require"lua.tableUtil"
local generator = require"mad.lang.generator"
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
		local path, name, ext = fn.split(fileName)
		local file = assert(io.open(fileName, 'r'))
		local inputStream = file:read('*a')
		file:close()
		local parser = lang.getParser(ext, 0, errors, run)
        if options.dump and options.dump == 'ast' then
            io.write(tableUtil.stringTable(parser:parse(inputStream, fileName)))
            io.write'\n'
            return
        end
        local starttime = os.clock()
        if not options.dump and (ext == 'madx' or options.bunchEvaluate) then
            local ast = parser:parse(inputStream, fileName)
        else
            local gen = generator.getGenerator(options.generator, errors, options.lambdatable)
            local source = gen:generate(parser:parse(inputStream, fileName))
		    if options.dump and options.dump ~= 'ast' then
		        io.write(source)
                io.write'\n'
	        else
		        local loadedCode, err = load(source,'@'..fileName)
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
	        end
	    end
        local endtime = os.clock()
        print("Total time:", endtime-starttime)
	end
	if options.interactive then
	    require'mad.lang.interactive'.interactive(errors)
	end
end

-- end ------------------------------------------------------------------------
return M
