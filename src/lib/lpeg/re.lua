--[[
Wrapper for re.lua.
Requires re.lua keeping the path and cpath as they were before.
]]

local pcp = package.cpath
local pp = package.path
package.cpath = ";;./lib/lpeg/lpeg-0.12/?.so;.\\lib\\lpeg\\lpeg-0.12\\?.dll;"
package.path = ";;./lib/lpeg/lpeg-0.12/?.lua;.\\lib\\lpeg\\lpeg-0.12\\?.lua;"
local re =  require"re"
package.cpath = pcp
package.path = pp
return re
