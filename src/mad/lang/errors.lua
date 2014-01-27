local M  = { help = {}, test = {} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME

SYNOPSIS
  local errorHandler = require "mad.lang.errorHandler"

DESCRIPTION
  

RETURN VALUES
  

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local new
mt.__call = function (...)
	return new(...)
end

-- modules ---------------------------------------------------------------------

local setCurrentChunkName = function(self, name)
	self.currentChunkName = name
	if not self._lineMap[self.currentChunkName] then
		self._lineMap[self.currentChunkName] = {}
	end
end

M.help.addToLineMap = [[
NAME
	addToLineMap
SYNOPSIS
	errorMap:addToLineMap(astNode.line, writtenLine, fileName)
DESCRIPTION
	maps a line in the written lua-code (where an error will be reported) to a line in the original mad-script (where the error actually happened).
RETURN VALUES
	none
]]
local addToLineMap = function(self, lineIn, lineOut, fileName)
	if not self._lineMap[self.currentChunkName][lineOut] then
		self._lineMap[self.currentChunkName][lineOut] = {}
	end
	self._lineMap[self.currentChunkName][lineOut].fileName = fileName
	if not self._lineMap[self.currentChunkName][lineOut].start or lineIn and self._lineMap[self.currentChunkName][lineOut].start > lineIn then
		self._lineMap[self.currentChunkName][lineOut].start = lineIn
	end
end

local function searchForLineMatch(self, line, chunkName)
	if self._lineMap[chunkName][line+1] then
		line = line+1
	else
		while line > 1 and not self._lineMap[chunkName][line] do
			line = line - 1
		end
	end
	return line
end

local function getNameAndLine(self, err, chunkName)
	local line = tonumber(string.match(err, ":(%d+):"))
	if not self._lineMap[chunkName][line] then
		line = searchForLineMatch(self, line, chunkName)
	end
	local name = self._lineMap[chunkName][line].fileName
	local realLine = self._lineMap[chunkName][line].start
	return name, realLine
end

local function getErrorMessage(err)
	return string.match(err,":%d+:%s*(.+)")
end

local function getStackTraceBack(err)
	return string.match(err, ".*stack traceback:%s*(.*)%s%[C%]: in function 'xpcall'")
end

local function createStackTable(self, stack)
	local stacktable = {}
	for s in string.gmatch(stack,"(.-)\n%s*") do
	    local chunkName = string.match(s,"(.-):%d+:")
		local name, line = getNameAndLine(self, s, chunkName)
		stacktable[#stacktable+1] = "\t"..name..":"..line..":"..string.match(s,":%d+:(.*)")
	end
	return stacktable
end

local function createStackErrorMessage(stacktable)
	local errmess = "\nstack traceback:"
	for i,v in pairs(stacktable) do
		errmess = errmess.."\n"..v
	end
	return errmess
end

local function getChunkName(err)
	return string.match(err, "(.*):%d+:")
end

local function translateLuaErrToMadErr(self, err, trace)
	local chunkName = getChunkName(err)
	local name, realLine = getNameAndLine(self, err, chunkName)
	local errmess = getErrorMessage(err)
	errmess = name..":"..realLine..": "..errmess
	local stack = getStackTraceBack(trace)
	local stacktable = createStackTable(self, stack)
	errmess = errmess..createStackErrorMessage(stacktable)
	return errmess
end

M.help.handleError = [[
NAME
	handleError
SYNOPSIS
	errorHandler:handleError(errorMessage)
DESCRIPTION
	takes an errormessage and changes it so that 
]]
local function handleError (self, err, trace)
	local errmess = translateLuaErrToMadErr(self, err, trace)
	return errmess
end

M.help.new = [[
DESCRIPTION
	creates a new instance of errorMap, able to handle one lua-chunk.
]]
new = function (_, ...)
	local self = {
		_lineMap = {},
		currentChunkName,
		setCurrentChunkName = setCurrentChunkName,
		addToLineMap = addToLineMap,
		searchForLineMatch = searchForLineMatch,
		getNameAndLine = getNameAndLine,
		createStackTable = createStackTable,
		translateLuaErrToMadErr = translateLuaErrToMadErr,
		handleError = handleError
	}
	return self
end

-- end ------------------------------------------------------------------------
return M
