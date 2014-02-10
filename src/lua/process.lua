local M = { help = {}, test = {} }

M.help.self = [==[
NAME
  lua.process
  
SYNOPSIS
  local pr    = require 'lua.process'
  local probj = pr.open( "NAME cmdlnarg", 'r'/'w')
  probj:write "String to write\n"
  probj:flush()
  probj:lines(...) -- ... = format
  probj:read(...)  -- ... = format
  probj:seek([whence [,offset]])
  probj:setvbuf(mode[,size])
  probj:close()
  
DESCRIPTION
  pr.open
    Opens NAME with command line arguments cmdlnarg in read or write mode (default: 'r').
    Returns a table containing the process and process' functions.
  probj:write(str)
    Writes str to the process, flushes with \n.
  probj:flush()
    Saves the data written to the process.
  probj:lines(...)
    Returns an iterator function that, each time it is called, reads the process
    according to the given formats (default: '*l').
  probj:read(...)
    Reads the process, according to the given formats, which specifies what to read.
    Formats:
      '*n': reads a number and returns it (returned as number, not string).
      '*a': reads all, starts from current position.
      '*l': reads the next line, skipping '\n'. Default format.
      number: reads number bytes and returns the string it has read.
  probj:seek([whenche[,offset]])
    Sets and gets the file postion, from start of file, to offset+base.
    base is set by whence, which can be 'set' (base is pos 0), 'cur' (base is
    current pos), or 'end' (base is end of file). whenche = cur and offset = 0 is default.
  probj:setvbuf(mode[,size])
    Sets the buffering mode for an output file. mode can be 'no' buffering, 'full',
    or 'line' buffering. Size specifies the buff_size.
  probj:close()
    Closes the process.

RETURN VALUES
  A table containing pr.open.

SEE ALSO
  http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
]==]

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

local pr = require'lua.process'
local gp = pr.open('gnuplot', 'w')
-- To make x11 window stay open after closing gnuplot.
-- local gp = pr.open('gnuplot -persist', 'w')
gp:write"set term png\n"
gp:write'set output "output.png"\n'
gp:write"plot sin(x)\n"
gp:close()
]]

return M
