local pcp = package.cpath
package.cpath = ";;./libs/lpeg/?.so;"..package.cpath
local re = require"libs.lpeg.re"
package.cpath = pcp
return re
