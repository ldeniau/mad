local M  = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.sequence -- build sequences

SYNOPSIS
  seq = require"mad.sequence"
  elm = require"mad.element"
  MB, MQ = elm.sbend, elm.quadrupole
  my_seq = seq 'name' {
    MQ 'QF', MB 'MB', MQ 'QD', MB 'MB',
  }

DESCRIPTION
  The module mad.sequence is a front-end to the factory of sequences and lines
  supported by MAD. The elements and the subsequences are copies of the table.

RETURN VALUES
  The object (table) that represents the flat sequence.

SEE ALSO
  mad.sequence, mad.beam, mad.object
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local marker = require"mad.element".marker

-- locals ----------------------------------------------------------------------

local type, rawget, rawset, ipairs, pairs = type, rawget, rawset, ipairs, pairs

M = object 'sequence' (M) -- root of all sequences

-- functions -------------------------------------------------------------------

local function add_element(self, elem_)
  local elem = elem_:cpy()
  self:insert(elem)                -- vector part

  local k = rawget(elem,'name')    -- dict part
  if k then
    local ref = rawget(self, k)
    if type(ref) == "table" then
      ref:insert(elem)
    else
      self[k] = {ref, elem}
    end
  else
    self[k] = elem
  end
end

local function add_sequence(self, seq)
  for _,v in ipairs(t) do
    add_element(self, v
  end
end

local function add_last_drift(self, ds)
  add_element(self, drift '' { length = ds })
  self.length = self.length + ds
end

-- methods ---------------------------------------------------------------------

-- M:new is inherited

function M:set(t)
  if type(t) ~= 'table' then
    error("invalid sequence description")
  end

  for _,v in ipairs(t) do
    if super(v) == M then
      add_sequence(self, v)
    else
      add_element(self, v)
    end
  end

  self.length = get_sequence_length(self)
  self.refer  = t.refer

  if t.length ~= nil and t.length > self.length then
    add_last_drift(self, t.length-self.length)
  end

  return self
end

-- metamethods -----------------------------------------------------------------

-- object used as a function
function M:__call(a)
  if type(a) == 'string' then
    return rawset(setmetatable({}, self), 'name', a)
  end

  if type(a) == 'table' then
    for k,v in pairs(a) do self[k] = v end
    return self
  end

  error ("invalid ".. self.name .." (implicit) call argument, string or table expected")
end

-- repetition
function M.__mul(a, b)
  error("TODO")
end

-- reflection
function M.__unm(a, b)
  error("TODO")
end 

-- end -------------------------------------------------------------------------
return M
