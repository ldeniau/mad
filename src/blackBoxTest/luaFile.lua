

local pr = require'lua.process'
local gp = pr.open('gnuplot','w')

gp:write"set term png\n"
gp:write'set output "output.png"\n'
gp:write"plot sin(x)\n"
gp:close()

