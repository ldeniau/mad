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
sbyte = function (s, i, j)
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
sdump = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return sdump(s)
end

local sfind = string.find
sfind = function (s, pattern, init, plain)
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
sformat = function (formatstring, ...)
    if is_lambda(formatstring) then
        formatstring = formatstring.__lambda()
    end
    return sformat(formatstring, ...)
end

local sgmatch = string.gmatch
sgmatch = function (s, pattern)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(pattern) then
        pattern = pattern.__lambda()
    end
    return sgmatch(s, pattern)
end

local sgsub = string.gsub
sgsub = function (s, pattern, repl, n)
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
slen = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return slen(s)
end

local slower = string.lower
slower = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return slower(s)
end

local smatch = string.match
smatch = function (s, pattern, init)
    if is_lambda(s) then
        s = s.__lambda()
    end
    if is_lambda(pattern) then
        pattern = pattern.__lambda()
    end
    if i and is_lambda(init) then
        init = init.__lambda()
    end
    return smatch(s, pattern, init)
end

local srep = string.rep
srep = function (s, n, sep)
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
sreverse = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return sreverse(s)
end

local ssub = string.sub
ssub = function (s, i, j)
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
supper = function (s)
    if is_lambda(s) then
        s = s.__lambda()
    end
    return supper(s)
end

-- test -----------------------------------------------------------------------



-- end ------------------------------------------------------------------------

return M
