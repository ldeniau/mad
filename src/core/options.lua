local M = { help = {}, test = {} }

M.help.self = [[
NAME
	core.options

]]

-- require --------------------------------------------------------------------


-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end

-- module ---------------------------------------------------------------------

M.files = {}


call = function (modSelf, arg)
	return M
end

M.processOptions = function(arg)
	local i = 0
	local handlingArgs = true
	repeat
		i = i + 1
		if handlingArgs and arg[i] == "-utest" then
			local index = string.find(arg[i+1], "%-")
			M.utest = {}
			while arg[i+1] and ( not index or index ~= 1 ) do
				i = i + 1
				M.utest[#utest+1] = arg[i]
				index = string.find(arg[i+1], "%-")
			end
		elseif handlingArgs and arg[i] == "-interactive" then
			print("WARNING: Interactive mode isn't implemented yet.")
		elseif handlingArgs and arg[i] == "-dumpAst" then
			M.dumpAst = true
		elseif handlingArgs and arg[i] == "--" then
			handlingArgs = false
		elseif handlingArgs and string.find(arg[i], "%-") == 1 then
			error("Unhandled argument "..arg[i])
		else
			M.files[#M.files+1] = arg[i]
		end
	until i >= #arg
end


-- end ------------------------------------------------------------------------
return M
