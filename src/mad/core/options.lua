local M = { help = {}, test = {} }

M.help.self = [[
NAME
	core.options
SYNOPSIS
	Reads the command line options and fills the options table.
]]

-- require --------------------------------------------------------------------
-- metamethods ----------------------------------------------------------------
-- module ---------------------------------------------------------------------

M.files = {}

local function processUTest(arg)
	M.utest = {}
	if arg[1] and (#arg > 1 or string.find(arg[1], "%s")) then
		local index = string.find(arg[1], "%-")
		if not index or index ~= 1 then
			local utestNames = table.remove(arg,1)
			for name in string.gmatch(utestNames, "(%S+)") do
				M.utest[#M.utest + 1] = name
			end
		end
	end
	return arg
end

local function processArgs(arg)
	local handlingArgs = true
	local index = string.find(arg[1], "%-")
	while index and index == 1 do
		local opt = table.remove(arg,1)
		if opt == "-utest" then
			processUTest(arg)
		elseif opt == "-interactive" then
			print("WARNING: Interactive mode isn't implemented yet.")
		elseif opt == "-dumpAst" then
			M.dumpAst = true
		elseif opt == "-dumpSource" then
			M.dumpSource = true
		else
			error("Unhandled argument "..opt)
		end
		if #arg == 0 then break end
		index = string.find(arg[1], "%-")
	end
	return arg
end

local function processFileNames(arg)
	for _,v in ipairs(arg) do
		M.files[#M.files+1] = v
	end
end

M.process = function(arg)
	local fileNameTable = processArgs(arg)
	processFileNames(fileNameTable)
end

-- end ------------------------------------------------------------------------
return M
