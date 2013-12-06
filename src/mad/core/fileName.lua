local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.util.openFile
DESCRIPTION
	contains functions for reading and closing files.
]]

-- require --------------------------------------------------------------------
local re = require"libs.lpeg.re"
local testApi = require"mad.test.api"

-- metamethods ----------------------------------------------------------------

-- module ---------------------------------------------------------------------

local grammarToSplitFileName = re.compile([[
filename <- ( <path>? <name> <extension>? ) -> fileName
extension <- ( "." {(!"." .)*} )
path <- ({( ( ! ("/" / "\") .)* ("/" / "\") )* })
name <- { (!("." %alpha) .)*}
]], { fileName = function(p,n,e)
		return p,n,e
	end
})

M.help.split = [[
SYNOPSIS
	local path, name, extension = splitFileName(string)
RETURN VALUES
	path, filename, extension
]]
M.split = function (fileName)
	return grammarToSplitFileName:match(fileName)
end

-- test -----------------------------------------------------------------------
function M.test.split()
	local name, ext, path = "name", "ext", "path/to/"
	local p,n,e = M.split(name)
	testApi.equals(p, "")
	testApi.equals(n, name)
	testApi.equals(e, nil)
	local p,n,e = M.split(name.."."..ext)
	testApi.equals(p, "")
	testApi.equals(n, name)
	testApi.equals(e, ext)
	local p,n,e = M.split(path..name)
	testApi.equals(p, path)
	testApi.equals(n, name)
	testApi.equals(e, nil)
	local p,n,e = M.split(path..name.."."..ext)
	testApi.equals(p, path)
	testApi.equals(n, name)
	testApi.equals(e, ext)
end

-- end ------------------------------------------------------------------------
return M
