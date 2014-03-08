local M  = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.table -- TFS table

SYNOPSIS
  table = require"mad.table"
  my_tab = table 'mytab' { column_name_list... }

DESCRIPTION
  The module mad.table creates TFS tables used by MAD. The columns can be
  accessed by name or by index and their content will grow automatically.
  If a name of a column is enclosed into a list, then its elements can be
  use to retrieve the index of the row. 

RETURN VALUE
  The TFS table.

EXAMPLE
  table = require"mad.table"
  tab = table 'survey' { {'name'}, 'x', 'y', 'z', 'phi', 'theta', 'rho' }
  tab:add{ 'drift', 0.1, 0.2, 0.5, 0, 0, 0 }
  tab:add{ name='mq', x=0.2, y=0.4, z=1, phi=0, theta=0, rho=0 }
  tab:write()         -- equivalent to tab:write"survey.tfs"
  print(tab.x[2])     -- x of 'mq'
  print(tab.mq.x)

SEE ALSO
  mad.sequence, mad.element, mad.beam
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local utils  = require"mad.utils"

-- locals ----------------------------------------------------------------------

local type, setmetatable = type, setmetatable
local pairs, ipairs = pairs, ipairs
local is_list = utils.is_list

-- metatable for the root of all tables
local MT = object {} 

 -- make the module the root of all tables
MT (M)
M.name = 'table'
M.kind = 'table'
M.is_table = true

-- methods ---------------------------------------------------------------------

function M:get_columns()
  return self._column
end

function M:set_columns(a)
  self._header = {}
  self._column = a
  for i,v in ipairs(a) do
    self[i] = {} ; self[v] = self[i]
  end
  return self
end

function M:add_header(a)
  local hdr = self._header
  for k,v in pairs(a) do hdr[#hdr+1] = v ; hdr[k] = v end
  return self
end

function M:add(a)
  local n = #self+1
  if #a == #self then
    for i,v in ipairs(a) do self[i][n] = v end
  else
    for k,v in  pairs(a) do self[k][n] = v end
  end
  return self
end

function M:write(a, columns)
  -- todo
  -- a can be a list of named parameters or the filename
end

-- metamethods -----------------------------------------------------------------

-- constructor of lines, can be unamed (inherit its name)
function MT:__call(a)
  if type(a) == 'string' then
    return function(t)
      if is_list(t) then
        self.__index = self         -- inheritance
        return setmetatable({name=a}, self):set_columns(t)
      end
      error ("invalid table constructor argument, list expected")
    end
  end

  if is_list(a) then
    self.__index = self             -- inheritance
    return setmetatable({}, self):set_columns(a)
  end
  error ("invalid table constructor argument, string expected")
end

function M.__add(tbl, a)
  return tab:add(a)
end

-- test suite -----------------------------------------------------------------------

M.test = require"mad.test.table"

-- end -------------------------------------------------------------------------
return M
