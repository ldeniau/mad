local exports = { }

local function dump(node, level)
   if not level then level = 1 end
   if type(node) == 'nil' then
      return "null"
   end
   if type(node) == "string" then
      return '"'..node..'"'
   end
   if type(node) == "number" then
      return node
   end
   if type(node) == "boolean" then
      return tostring(node)
   end
   if type(node) == "function" then
      return tostring(node)
   end

   local buff = { }
   local dent = string.rep("    ", level)
   local tput = table.insert

   if #node == 0 and next(node, nil) then
      tput(buff, "{")
      local i_buff = { }
      local p_buff = { }
      for k,data in pairs(node) do
         tput(buff, "\n"..dent..dump(k)..': '..dump(data, level + 1))
         if next(node, k) then
            tput(buff, ",")
         end
      end
      tput(buff, "\n"..string.rep("    ", level - 1).."}")
   else
      tput(buff, "[")
      for i,data in pairs(node) do
         tput(buff, "\n"..dent..dump(data, level + 1))
         if i ~= #node then
            tput(buff, ",")
         end
      end
      tput(buff, "\n"..string.rep("    ", level - 1).."]")
   end

   return table.concat(buff, "")
end

exports.dump = dump

local ID = 0
exports.genid = function()
   ID = ID + 1
   return '__'..ID
end

function exports.extend(base, with)
   with.__super = base
   with.__index = with
   return setmetatable(with, { __index = base, __call = base.__call })
end

function exports.tableMerge(...)
	local args = {...}
	local ret = {}
	for i,v in pairs(args[1]) do
		ret[i] = v
	end
	for i=2, #args do
		for k,v in pairs(args[i]) do
			if type(v) == "table" then
				if type(ret[k] or false) == "table" then
					ret[k] = exports.tableMerge(ret[k] or {}, args[i][k] or {})
				else
					ret[k] = v
				end
			else
				ret[k] = v
			end
		end
	end
	return ret
end

function exports.printTable(t,num)
	local n = num or 0
	local tabs = ""
		for i = 1, n do
			tabs = tabs.."-"
		end	
	if type(t) == "table" then
		n = n + 1
		for i,v in pairs(t) do
			print(tabs..tostring(i))
			exports.printTable(v, n)
		end
	else
		if t~=nil then
			print(tabs..tostring(t))
		else
			print(tabs.."nil")
		end
	end
end

local extGramm = require"re".compile([[
filename <- ( { (!("." %alpha) .)*} ( "." {(!"." .)*} ) ) -> fileName
]], { fileName = function(n,e)
		return n,e
	end
})

function exports.getNamepathAndExtension(fileName)
	return extGramm:match(fileName)
end

function exports.openFile(fileName)
	local file = assert(io.open(fileName, 'r'))
	local istream = file:read('*a')
	file:close()
	return istream
end

return exports
