local M = { help = {}, test = {} }

M.help = [[
NAME
  lua.process
  
SYNOPSIS
  
]]

local function open(str, op)
    return assert(io.popen(str, op))
end

local function close(self)
    return self.close()
end

local function write(self, ...)
    return self:write(...)
end

local function read(self,...)
    return self:read(...)
end

local mt = { 
    __call = function(str) return {} end 
}
setmetatable(M,mt)

M.help.gnuplot = [[
Example usage for gnuplot:

local pr = require'lua.process'
local gp = pr.open('gnuplot', 'w')
-- To make x11 window stay open after closing gnuplot.
-- local gp = pr.open('gnuplot -persist', 'w')
gp:write"set term png"
gp:write'set output "output.png"'
gp:write"plot sin(x)"
gp:close()
]]

return M
