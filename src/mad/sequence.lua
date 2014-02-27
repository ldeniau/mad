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
  The module mad.sequence creates new sequences and lines supported by MAD.
  The elements are not copied but referenced, i.e. store the orinal ones.

RETURN VALUES
  The object (table) that represents the flat sequence.

SEE ALSO
  mad.sequence, mad.element, mad.beam
]]

-- requires --------------------------------------------------------------------

local object  = require"mad.object"
local element = require"mad.element"

-- locals ----------------------------------------------------------------------

local getmetatable, setmetatable = getmetatable, setmetatable
local type, ipairs = type, ipairs
local is_list = object.is_list

-- metatable for the root of all sequences
local MT = object {} 

 -- make the module the root of all sequences
MT (M)
M.name = 'sequence'
M.is_sequence = true

-- functions -------------------------------------------------------------------

-- utils
local function test_membership(seq, a)
  if seq[a.i_pos] ~= a then
    error('invalid sequence element '..a.name)
  end
end

local function show_list(t, list)
  local a
  for _,v in ipairs(list) do
    a = t[v]
    if a then io.write(', ', v, '= ', tostring(a)) end
  end
end

-- search
local function find_index_by_ref(t, a, start)
  for i=start or 1,#t do -- linear search
    if t[i] == a then return i end
  end
end

local function find_index_by_name(t, name, start)
  for i=start or 1,#t do -- linear search
    if t[i].name == name then return i end
  end
  return nil
end

local function find_index_by_pos(t, s_pos, start)
  for i=start or 1,#t do  -- binary search: TODO
    if t[i].s_pos >= s_pos then return i end
  end
  return nil
end

-- array
local function update_index(t, start)
  for i=start or 1,#t do t[i].i_pos = i end
end

-- dictionnary
local function add_element_key(self, elem)
  local name = elem.name              -- dict part
  local ref = self[name]
  if ref == nil then                  -- not yet registered
    self[name] = elem
  elseif ref.is_element then          -- already one element
    self[name] = {ref, elem}
  else                                -- already many elements
    ref[#ref+1] = elem
  end
end

-- shadow elements (special inheritance)
local function shadow_class(elem)
  return getmetatable(elem).__index:class()
end

local function shadow_element(elem, at, from, refer, i)
  return setmetatable(
    {i_pos=i, s_pos=1e100, at=at, from=from, refer=refer, class=shadow_class},
    {__index=elem, __newindex=elem})
end

-- construction
local function add_element(self, elem, at, from, refer)
  local i = #self+1
  self[i] = shadow_element(elem, at, from, refer, i)
  add_element_key(self, self[i])
end

local function add_sequence(self, seq, at, from, refer, rev)
  if rev and rev<0 then
    for i=#seq,1,-1 do
      add_element(self, seq[i], at, from, refer)
    end
  else
    for i=1,#seq do
      add_element(self, seq[i], at, from, refer)
    end
  end
end

local function add_list(self, lst, at, from, refer, rev)
  local n = (lst._rep or 1) * (rev or 1)
  local j_start, j_end, j_step

  if n<0 then
      n, j_start, j_end, j_step = -n, #lst, 1, -1
  else
         j_start, j_end, j_step =     1, #lst,  1
  end

  for i=1,n do
    for j=j_start,j_end,j_step do
      local v = lst[j]
      if v.is_element then
        add_element(self, v, at, from, refer)
      elseif v.is_sequence then
        add_sequence(self, v, at, from, refer, j_step)
      elseif is_list(v) then
        add_list(self, v, at, from, refer, j_step) -- lists can be recursive
      else
        error('invalid list element at slot '..j..' at sequence slot '..(#self+1))
      end
    end
  end
end

local function add_item(self, a, at, from, refer)
      if a.is_element  then add_element  (self, a, at, from, refer)
  elseif a.is_sequence then add_sequence (self, a, at, from, refer)
  elseif is_list(a)    then add_list     (self, a, at, from, refer)
  else error('invalid item in construction of sequence '..(self.name or ''))
  end
end

-- methods ---------------------------------------------------------------------

local sequ_field = {  'refer', 'refpos', 'l' }

function M:show(disp)
  io.write('sequence: ', self.name, '\n')
  for i,v in ipairs(self) do v:show(disp) end
  io.write('endsequence: ', self.name, '\n')
end

function M:show_madx(disp)
  io.write(self.name, ': sequence')
  show_list(self, sequ_field)
  io.write(';\n')
  for i,v in ipairs(self) do v:show_madx(disp) end
  io.write('endsequence;\n')
end

-- :add(item [, pos [, from [, refer]]])                      :positional params
-- :add{[item=]item [, at=pos [, from='from' [, refer='refer']]]}  :named params
-- item  is elem|list|sequ
-- from  is 'start'|'end'|'previous'|'next'|'name'
-- refer is 'entry'|'centre'|'exit'|'name'

function M:add(a, at, from, refer)
  if at or not a.at then    -- positional params
    add_item(self, a, at, from, refer)
  elseif is_list(a) then    -- named params
    add_item(self, a.item or a[1], a.at, a.from, a.refer)
  else
    error("invalid set of parameters in incremental sequence construction")
  end
  return self
end

function M:done() -- TODO
  return self
end

function M:set(a)
  return self:add(a):done()
end

-- metamethods -----------------------------------------------------------------

-- constructor of sequences, can be anonymous
function MT:__call(a)
  if type(a) == 'string' then
    return function(t)
      if is_list(t) then
        self.__index = self         -- inheritance
        return setmetatable({name=a}, self):set(t)
      end
      error ("invalid constructor argument, list expected")
    end
  end

  if is_list(a) then
    self.__index = self             -- inheritance
    return setmetatable({}, self):set(a)
  end

  error ("invalid constructor argument, string expected")
end

-- construction
function M.__add(seq, a)
  return seq:add(a)
end

-- repetition
function M.__mul(n, seq)
  if type(seq) == 'number' then n, seq = seq, n end
  return { _rep=n, seq }
end

-- reflection
function M.__unm(seq, _)
  return { _rep=-1, seq }
end 

--------------------------------------------------------------------------------
-- TODO ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[
local function flatten(self, name)
  local t = { name=name or self.name }

  for i,v in ipairs(self) do
    if type(v) == 'function' then v = v() end
    if v.is_sequence then
      add_sequence(t, v)
    elseif v.is_element then
      add_element(t, v)
    elseif is_list(v) then
      add_list(t, v)
    else
      error('invalid sequence element at slot '..i)
    end
  end

  return localise(t)
end
--]]

-- geometry -- TODO: at, from, refer, refpos
local function localise(self, start)
  local s_pos = start and v[start].s_pos or 0
  for i=start or 1,#self do
    self[i].s_pos = s_pos
    if self[i].l then s_pos = s_pos + self[i].l end
  end
  if not self.length then self.length = s_pos end
  return self
end

local function insert_element_key(self, elem)
  local name = elem.name              -- dict part
  local ref = self[name]
  if ref == nil then                  -- not yet registered
    self[name] = elem
  elseif ref.is_element then          -- already one element
    self[name] = ref.i_pos < elem.i_pos and {ref, elem} or {elem, ref}
  else                                -- already many elements
    table.insert(ref, find_index_by_idx(ref, elem.i_pos), elem)
  end
end

local function remove_element_key(self, elem)
  local name = elem.name              -- dict part
  local ref = self[name]
  if ref.is_element then              -- single element
    self[name] = nil
  else                                -- list of elements
    table.remove(ref, find_index_by_ref(ref, elem))
    if #ref == 1 then self[name] = ref[1] end -- was a pair
  end
end

-- edition -- TODO: check s_pos and l
local function insert_element(self, elem, before)
  test_membership(self, before)
  local i = before.i_pos
  table.insert(self, i, elem)
  update_index(self, i)
  insert_element_key(self, elem)
end

local function remove_element(self, elem)
  test_membership(self, elem)
  local i = elem.i_pos
  remove_element_key(self, elem)
  table.remove(self, i)
  update_index(self, i)
end

local function replace_element(self, old_elem, new_elem)
  test_membership(self, old_elem)
  local i = old_elem.i_pos
  self[i] = new_elem
  new_elem.i_pos = i
  remove_element_key(self, elem)
  insert_element_key(self, elem)
end

local function swap_elements(self, elem1, elem2, update_key)
  test_membership(self, elem1)
  test_membership(self, elem2)
  local i1, i2 = elem1.i_pos, elem2.i_pos
  self[i1], self[i2] = elem2, elem1
  elem1.i_pos, elem2.i_pos = i2, i1
  if update_key then
    remove_element_key(self, elem1)
    remove_element_key(self, elem2)
    insert_element_key(self, elem1)
    insert_element_key(self, elem2)
  end
end

function M:remove(a, count) -- TODO
  if type(a) == 'string' then
    a = self[a]
    if is_list(a) then a = a[count or 1] end
  end
  remove_element(self, a)
end

function M:insert(a, at, count) -- TODO
  if type(at) == 'string' then
    at = self[at]
    if is_list(at) then at = at[count or 1] end
  elseif type(at) == 'number' then
    at = self[find_index_by_pos(self, at)]
  end
  insert_element(self, a, at)
end

-- end -------------------------------------------------------------------------
return M
