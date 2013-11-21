local M  = { help = {}, test = {}, _author = "Martin Valen", _year = 2013 }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.compiler.errorHandler -- Methodical Accelerator Design package

SYNOPSIS
  local errorHandler = require "mad.lang.errorHandler"

DESCRIPTION
  

RETURN VALUES
  

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
local util = require"mad.lang.util"

-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local new
mt.__call = function (...)
	return new(...)
end

-- modules ---------------------------------------------------------------------

local addToLineMap = function(self, lineIn, lineOut, fileName)
	if not self._lineMap[lineOut] then
		self._lineMap[lineOut] = {}
	end
	self._lineMap[lineOut].fileName = fileName
	if not self._lineMap[lineOut].start or lineIn and self._lineMap[lineOut].start > lineIn then
		self._lineMap[lineOut].start = lineIn
	end
end

local function searchForLineMatch(self, line)
	if self._lineMap[line+1] then
		line = line+1
	else
		while line > 1 and not self._lineMap[line] do
			line = line - 1
		end
	end
	return line
end

local function getNameAndLine(self, err)
	local line = tonumber(string.match(err, ":(%d+):"))
	if not self._lineMap[line] then
		line = searchForLineMatch(self, line)
	end
	local name = self._lineMap[line].fileName
	local realLine = self._lineMap[line].start
	return name, realLine
end

local function getErrorMessage(err)
	return string.match(err,":%d+:%s*(.+)\n%s*stack traceback")
end

local function getStackTraceBack(err)
	return string.match(err, ".*stack traceback:%s*(.*)%s%[C%]: in function 'xpcall'")
end

local function createStackTable(self, stack)
	local stacktable = {}
	for s in string.gmatch(stack,"(.-)\n%s*") do
		if string.find(s, "%.mad") then
			local name, line = getNameAndLine(self, s)
			stacktable[#stacktable+1] = "\t"..name..":"..line..":"..string.match(s,":%d+:(.*)")
		elseif string.find(s, "%.lua") then
			stacktable[#stacktable+1] = "\t"..s
		end
	end
	return stacktable
end

local function createStackErrorMessage(stacktable)
	local errmess = ""
	for i,v in pairs(stacktable) do
		errmess = errmess.."\n"..v
	end
	return errmess
end

local function translateLuaErrToMadErr(self, err)
	local name, realLine = getNameAndLine(self, err)
	local errmess = getErrorMessage(err)
	errmess = name..":"..realLine..": "..errmess
	local stack = getStackTraceBack(err)
	local stacktable = createStackTable(self, stack)
	errmess = errmess..createStackErrorMessage(stacktable)
	return errmess
end
	
local function handleError (self, err)
	local mad = string.find(err,"(%.mad)")
	local lua = string.find(err,"(%.lua)")
	if mad and ( not lua or mad < lua ) then
		local errmess = translateLuaErrToMadErr(self, err)
		error(errmess,0)
	else
		return error(err,0)
	end
end

new = function (_, ...)
	local self = {
		_lineMap = {},
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
