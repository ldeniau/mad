local M  = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.line -- build lines

SYNOPSIS
  line = require"mad.line"
  my_line = line { element_list... }

DESCRIPTION
  The module mad.line creates new lines (raw sequences) supported by MAD.
  The elements are not copied but referenced, i.e. store the orginal ones and the
  list are not flatten. They will be flatten only when put in a sequence.

RETURN VALUE
  The line (table) that represents the line unmodified (not flatten).

EXAMPLE
  line = require"mad.line"
  elm  = require"mad.element"
  MB, MQ = elm.sbend, elm.quadrupole
  my_line = line {
    MQ 'QF', MB 'MB', MQ 'QD', MB 'MB',
  }

SEE ALSO
  mad.sequence, mad.element, mad.beam
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local utils  = require"mad.utils"

-- locals ----------------------------------------------------------------------

local type, setmetatable = type, setmetatable
local is_list = utils.is_list

-- metatable for the root of all lines
local MT = object {} 

 -- make the module the root of all lines
MT (M)
M.name = 'line'
M.kind = 'line'
M.is_line = true

-- methods ---------------------------------------------------------------------

function M:mangled_name()
  local rep  = self._rep
  local name = rep and self[1].name or self.name

  if rep then
        if rep == -1 then name = '-'..name
    elseif rep ~=  1 then name = rep..'*'..name
    end
  end
  
  return name
end

-- metamethods -----------------------------------------------------------------

-- constructor of lines, can be anonymous
function MT:__call(a)
  if type(a) == 'string' then
    return function(t)
      if is_list(t) then
        t.name = a
        self.__index = self         -- inheritance
        return setmetatable(t, self)
      end
      error ("invalid line constructor argument, list expected")
    end
  end

  if is_list(a) then
    self.__index = self             -- inheritance
    return setmetatable(a, self)
  end

  error ("invalid line constructor argument, string expected")
end

-- repetition
function M.__mul(n, line)
  if type(line) == 'number' then n, line = line, n end
  return M { _rep=n, line }
end

-- reflection
function M.__unm(line, _)
  return M { _rep=-1, line }
end 

-- test suite -----------------------------------------------------------------------

M.test = require"mad.test.line"

-- end -------------------------------------------------------------------------
return M
