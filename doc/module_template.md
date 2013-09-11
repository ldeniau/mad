-- module XX

local M = { help = {}, test = {} }

-- dependencies

M.sequence = require "mad.sequence"

-- functions

local function toto()
end

-- services

M.help.self = [[
This is a paragraph.  It's quite
short.

   This paragraph will result in an indented block of
   text, typically used for quoting other text.

This is another one.
]]

M.new = function () 
end

M.help.new = [[
  return a new built bending magnet
]]

M.test.new = 

-- end of module

return M

