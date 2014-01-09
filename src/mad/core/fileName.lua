local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.util.openFile
DESCRIPTION
	contains functions for reading and closing files.
]]

-- require --------------------------------------------------------------------
local re = require"mad.lang.re"

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
function M.test:split(ut)
	local name, ext, path = "name", "ext", "path/to/"
	local p,n,e = M.split(name)
	ut:equals(p, "")
	ut:equals(n, name)
	ut:equals(e, nil)
	local p,n,e = M.split(name.."."..ext)
	ut:equals(p, "")
	ut:equals(n, name)
	ut:equals(e, ext)
	local p,n,e = M.split(path..name)
	ut:equals(p, path)
	ut:equals(n, name)
	ut:equals(e, nil)
	local p,n,e = M.split(path..name.."."..ext)
	ut:equals(p, path)
	ut:equals(n, name)
	ut:equals(e, ext)
end

-- end ------------------------------------------------------------------------
return M
