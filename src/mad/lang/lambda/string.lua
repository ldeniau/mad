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

local sbyte = string.byte
string.byte = function (s, i, j)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if i and is_lambda(i) then
        i = i.__lambda()
    end
    if j and is_lambda(j) then
        j = j.__lambda()
    end
    return sbyte(s, i, j)
end

local sdump = string.dump
string.dump = function (s)
    if is_lambda(s) then
        s = s.__lambda
    end
    return sdump(s)
end

local sfind = string.find
string.find = function (s, pattern, init, plain)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(pattern) then
        pattern = pattern.__lambda()
    end
    if init and is_lambda(init) then
        init = init.__lambda()
    end
    if plain and is_lambda(plain) then
        plain = plain.__lambda()
    end
    return sfind(s, pattern, init, plain)
end

local sformat = string.format
string.format = function (formatstring, ...)
    if is_lambda(formatstring) then
        formatstring = formatstring.__lambda()
    end
    local vararg = {}
    for i,v in ipairs({...}) do
        if is_lambda(v) then
            vararg[#vararg+1] = v.__lambda()
        else
            vararg[#vararg+1] = v
        end
    end
    return sformat(formatstring, table.unpack(vararg))
end

local sgmatch = string.gmatch
string.gmatch = function (s, pattern)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(pattern) then
        pattern = pattern.__lambda()
    end
    return sgmatch(s, pattern)
end

local sgsub = string.gsub
string.gsub = function (s, pattern, repl, n)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(pattern) then
        pattern = pattern.__lambda()
    end
    if is_lambda(repl) then
        repl = repl.__lambda()
    end
    if n and is_lambda(n) then
        n = n.__lambda()
    end
    return sgsub(s, pattern, repl, n)
end

local slen = string.len
string.len = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return slen(s)
end

local slower = string.lower
string.lower = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return slower(s)
end

local smatch = string.match
string.match = function (s, pattern, init)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(pattern) then
        pattern = pattern.__lambda()
    end
    if init and is_lambda(init) then
        init = init.__lambda()
    end
    return smatch(s, pattern, init)
end

local srep = string.rep
string.rep = function (s, n, sep)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(n) then
        n = n.__lambda()
    end
    if sep and is_lambda(sep) then
        sep = sep.__lambda()
    end
    return srep(s, n, sep)
end

local sreverse = string.reverse
string.reverse = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return sreverse(s)
end

local ssub = string.sub
string.sub = function (s, i, j)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(i) then
        i = i.__lambda()
    end
    if j and is_lambda(j) then
        j = j.__lambda()
    end
    return ssub(s, i, j)
end

local supper = string.upper
string.upper = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return supper(s)
end

-- test -----------------------------------------------------------------------

M.test = load_test and require"mad.lang.lambda.test.string" or {}


-- end ------------------------------------------------------------------------

return M
