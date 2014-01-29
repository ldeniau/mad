local M  = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.__lambda -- MAD module containing helper functions for the lambda-function.

SYNOPSIS
  

DESCRIPTION
  

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local is_lambda = is_lambda

-- module ---------------------------------------------------------------------

local tconcat = table.concat
tconcat = function (list , sep , i , j)
    if is_lambda(list) then
        list = list.__lambda()
    end
    return tconcat(list, sep, i, j)
end

local tinsert = table.insert
tinsert = function (list, pos, value)
    if is_lambda(list) then
        list = list.__lambda()
    end
    return tinsert(list, pos, value)
end

local tremove = table.remove
tremove = function (list , pos)
    if is_lambda(list) then
        list = list.__lambda()
    end
    return tremove(list, pos)
end

local tsort = table.sort
tsort = function (list , comp)
    if is_lambda(list) then
        list = list.__lambda()
    end
    return tsort(list, comp)
end

local tunpack = table.unpack
tunpack = function (list , i , j)
    if is_lambda(list) then
        list = list.__lambda()
    end
    return tunpack(list, i, j)
end

-- test -----------------------------------------------------------------------



-- end ------------------------------------------------------------------------

return M
