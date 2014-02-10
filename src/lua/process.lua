local M = { help = {}, test = {} }

M.help.self = [[
NAME
  lua.process
  
SYNOPSIS
  
]]

local function lines(self,...)
    return self.process:lines(...)
end

local function flush(self)
    return self.process:flush()
end

local function seek(self,wh,off)
    return self.process:seek(wh,off)
end

local function setvbuf(self,md,sz)
    return self.process:setvbug(md,sz)
end

local function close(self)
    return self.process.close()
end

local function write(self, ...)
    return self.process:write(...)
end

local function read(self,...)
    return self.process:read(...)
end

function M.open(str, op)
    local pr, err = io.popen(str, op)
    if not pr then return err end
    return {
        process = pr,
        open = open,
        write = write,
        read = read,
        close = close,
        lines = lines,
        flush = flush,
        seek = seek,
        setvbuf = setvbuf
    }
end

M.help.gnuplot = [[
Example usage for gnuplot:

local pr = require'lua.process'()
local gp = pr.open('gnuplot', 'w')
-- To make x11 window stay open after closing gnuplot.
-- local gp = pr.open('gnuplot -persist', 'w')
gp:write"set term png\n"
gp:write'set output "output.png"\n'
gp:write"plot sin(x)\n"
gp:close()
]]

return M
