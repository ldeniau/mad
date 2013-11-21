local M = { help={}, test={}, _author="MV", _year=2013 }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  instEval.include

SYNOPSIS
  local defsInstEvalInclude = require"mad.lang.parser.actions.instEval.include".actions
  But this should be done in instEvalStmt.lua

DESCRIPTION
  Implements C/C++-style include.

RETURN VALUES
  

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local env = require"mad.lang.environment"
local re = require"re"
local util = require"mad.lang.util"

-- module ---------------------------------------------------------------------
local defs = {}
defs.instEval = {}

local pattName = [[
	arg <- ( s ( <string> / "(" s <string> s ")" ) {} ) -> args
	s <- %s*
	string	<- ("'" { (!"'" .)* } "'") / ('"' { (!'"' .)* } '"')
]]
local grammarName = re.compile(pattName, { args = function(st,pos) return st, pos end })

local function tryToOpenFile(name)
	local namelist = string.gsub(package.mpath, "%?", name)
	local file
	for filename in string.gmatch(namelist, ";+([^;]+)") do
		file = io.open(filename,'r')
		if file then
			return file, filename
		end
	end
	error("Unable to open file: "..name)
end

function defs.instEval.include(istream, pos)
	local name, endpos = grammarName:match(istream)
	local file, fileName = tryToOpenFile(name)
	local newIStream = file:read('*a')
	file:close()
	local parser = env.parser()
	local ret = parser:parse(newIStream, fileName)
	ret.type = "BlockStatement"
	return pos+endpos-1,ret
end

M.actions = defs

-- end ------------------------------------------------------------------------
return M
