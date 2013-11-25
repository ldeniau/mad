local M = { help = {}, test = {}, _author = "Martin Valen", _year = 2013 }

M.help.self = [[
NAME
	mad.util.openFile
DESCRIPTION
	contains functions for reading and closing files.
]]

-- require --------------------------------------------------------------------
local re = require"./lib/lpeg/re"

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

M.help.splitFileName = [[
SYNOPSIS
	local path, name, extension = splitFileName(string)
RETURN VALUES
	path, filename, extension
]]
M.splitFileName = function (fileName)
	return grammarToSplitFileName:match(fileName)
end

M.help.getInputStream= [[
NAME
	getInputStream
SYNOPSIS
	local inputStream = getInputStream(fileName)
DESCRIPTION
	opens a file and returns its stream.
INPUT VALUES
	fileName: The name of the file to be opened
RETURN VALUES
	inputStream
]]
M.getInputStream = function (fileName)
	local file = assert(io.open(fileName, 'r'))
	local istream = file:read('*a')
	file:close()
	return istream
end

-- end ------------------------------------------------------------------------
return M
