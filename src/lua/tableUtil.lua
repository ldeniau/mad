local M = { test = {}, help = {} }

M.help = [[
NAME
  lua.tableUtil
SYNOPSIS
  local tableUtil = require'lua.tableUtil'
  tableUtil.printTable(table[, level])
  tableUtil.stringTable(table[, level])
DESCRIPTION
  printTable
    prints table and recursively calls itself if tables values are themselves tables.
  stringTable
    returns table as a string.
    
RETURN VALUES
  A table containing the functions
  
SEE ALSO
  none

]]

-- module ---------------------------------------------------------------------

function M.printTable(t,level)
	local n = level or 0
	local tabs = ""
		for i = 1, n do
			tabs = tabs.."-"
		end	
	if type(t) == "table" then
		n = n + 1
		for i,v in pairs(t) do
			print(tabs..tostring(i))
			M.printTable(v, n)
		end
	else
		if t~=nil then
			print(tabs..tostring(t))
		else
			print(tabs.."nil")
		end
	end
end

function M.stringTable(t,level)
	local n = level or 0
	local ret = {}
	local tabs = ""
		for i = 1, n do
			tabs = tabs.."-"
		end	
	if type(t) == "table" then
		n = n + 1
		for i,v in pairs(t) do
			ret[#ret+1] = tabs..tostring(i).."\n"
			ret[#ret+1] = M.stringTable(v, n)
		end
	else
		if t~=nil then
			ret[#ret+1] = tabs..tostring(t).."\n"
		else
			ret[#ret+1] = tabs.."nil".."\n"
		end
	end
	return table.concat(ret)
end

-- end ------------------------------------------------------------------------

return M
