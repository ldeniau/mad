local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.utils -- utilities

SYNOPSIS
  U = require"mad.utils"
  is_list, show_list = U.is_list, U.show_list

DESCRIPTION
  The module mad.utils provides utility functions.
  It provides functions to deal with lists, that is Lua table without metatable.
  
EXAMPLES
  is_list = require"mad.utils".is_list
  is_list { x=0, y=0 }                  -- return true
  is_list (object {})                   -- return false

SEE ALSO
  mad.object
]]

-- locals ----------------------------------------------------------------------

local type, getmetatable = type, getmetatable
local ipairs, pairs = ipairs, pairs

-- functions -------------------------------------------------------------------

local is_list = function (a)
  return type(a) == 'table' and getmetatable(a) == nil
end

local function show_in_fields(lst, disp, equ, sep)
  local i, n, k, v = false, #lst
  for _,s in ipairs(disp) do
    if is_list(s) then k, v = s[2], lst[s[1]] else k, v = s, lst[s] end
    if v then
      if i then io.write(sep) else i = true end
      if type(k) ~= 'number' or k > n then io.write(k, equ) end
      io.write(tostring(v))
    end
  end
end

local function show_out_fields(lst, disp, equ, sep)
  local i, n = false, #lst
  for k,v in pairs(lst) do
    if not disp[k] then
      if i then io.write(sep) else i = true end
      if type(k) ~= 'number' or k > n then io.write(k, equ) end
      io.write(tostring(v))
    end
  end
end

local function show_all_fields(lst, disp, equ, sep)
  local i, n = false, #lst
  for k,v in pairs(lst) do
    if i then io.write(sep) else i = true end
    if type(k) ~= 'number' or k > n then io.write(k, equ) end
    io.write(tostring(v))
  end
end

-- methods --------------------------------------------------------------------

M.is_list = is_list

M.show_list = function (lst, disp, fmt)
  local equ, sep

  if is_list(fmt) then equ, sep = fmt[1], fmt[2]
  elseif     fmt  then equ, sep = fmt   , ', '
  else                 equ, sep = '= '  , ', '
  end 

      if disp and disp._not then show_out_fields(lst, disp, equ, sep) -- only unspecified
  elseif disp               then show_in_fields (lst, disp, equ, sep) -- only specified
  else                           show_all_fields(lst, disp, equ, sep) -- all
  end    
end

-- end -------------------------------------------------------------------------
return M
