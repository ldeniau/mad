local M  = { help = {}, _id = "mad.initializer.require", _author = "Martin Valen", _year = 2013 }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.initializer.require -- Methodical Accelerator Design module containing a require function for madl-files.

SYNOPSIS
  Will never be used by the user. Is appended to the end of package.loaders, making the search path through the loaders be: lua->.so/.dll->.mad.

DESCRIPTION
  

RETURN VALUES
  Returns info about the module.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local run = require"mad.lang.run"
-- module ---------------------------------------------------------------------

local codes = {}

local function callRun(name)
	return run.runLuaCode(codes[name])
end

local function loader(name)
	local namelist = string.gsub(package.mpath, "%?", name)
	local file, fileName
	do
		for filename in string.gmatch(namelist, ";+([^;]+)") do
			file = io.open(filename,'r')
			if file then
				fileName = filename
				break
			end
		end
		local istream = file:read('*a')
		file:close()
	end
	codes[name] = run.compile(require"mad.lang.preParserGenerator"("mad"), istream, fileName)
	return callRun
end

table.insert(package.loaders,loader)


-- end -------------------------------------------------------------------------

return M
