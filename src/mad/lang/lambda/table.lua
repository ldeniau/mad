local M  = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.lambda.table

SYNOPSIS
  Contains overloaded functions of the table-library to work with lambda functions.

DESCRIPTION
  All functions in the table library that takes a table as argument have been
  overloaded to call lambdas before doing the actual work.
  lambda = { __lambda = func }
    table.xxx( lambda ) -> table.xxx( lambda.__lambda() )
  Exception:
    table.pack. pack will park the lambda into a table, not the lambdas return value.

RETURN VALUES
  A table with tests and help.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local is_lambda = is_lambda

-- module ---------------------------------------------------------------------

local tconcat = table.concat
table.concat = function (list , sep , i , j)
    while is_lambda(list) do
        list = list.__lambda()
    end
    while sep and is_lambda(sep) do
        sep = sep.__lambda()
    end
    while i and is_lambda(i) do
        i = i.__lambda()
    end
    while j and is_lambda(j) do
        j = j.__lambda()
    end
    return tconcat(list, sep, i, j)
end

local tinsert = table.insert
table.insert = function (list, pos, value)
    while is_lambda(list) do
        list = list.__lambda()
    end
    while is_lambda(pos) do
        pos = pos.__lambda()
    end
    while value and is_lambda(value) do
        value = value.__lambda()
    end
    while value do
        return tinsert(list, pos, value)
    end
    return tinsert(list,pos)
end

local tremove = table.remove
table.remove = function (list , pos)
    while is_lambda(list) do
        list = list.__lambda()
    end
    while pos and is_lambda(pos) do
        pos = pos.__lambda()
    end
    return tremove(list, pos)
end

local tsort = table.sort
table.sort = function (list , comp)
    while is_lambda(list) do
        list = list.__lambda()
    end
    while comp and is_lambda(comp) do
        comp = comp.__lambda()
    end
    return tsort(list, comp)
end

local tunpack = table.unpack
table.unpack = function (list , i , j)
    while is_lambda(list) do
        list = list.__lambda()
    end
    while i and is_lambda(i) do
        i = i.__lambda()
    end
    while j and is_lambda(j) do
        j = j.__lambda()
    end
    return tunpack(list, i, j)
end

-- test -----------------------------------------------------------------------

M.test = load_test and require"mad.lang.lambda.test.table" or {}


-- end ------------------------------------------------------------------------

return M
