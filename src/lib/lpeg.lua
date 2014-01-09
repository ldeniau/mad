local pcp = package.cpath
package.cpath = ";;./lib/lpeg/lpeg-0.12/?.so;.\\lib\\?\\lpeg-0.12\\?.dll;"
local lpeg = require"lpeg"
package.cpath = pcp
return lpeg
