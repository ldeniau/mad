local M  = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.lambda.string

SYNOPSIS
  Overloads the string library for usage with lambda-function.

DESCRIPTION
  All functions are overloaded to call the lambda-function with no arguments if
  it is received as an argument.
    lambda = { __lambda = func }
    string.xxx( lambda ) -> string.xxx( lambda.__lambda() )
  Exception:
    string.dump will dump the function, not the function called.
      lambda = { __lambda = func }
      string.dump( lambda ) -> string.dump( lambda.__lambda )
    string.format. Lambdas sent to string.format will need to be explicitly called.

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
    while is_lambda(s) do
        s = s.__lambda()
    end
    while i and is_lambda(i) do
        i = i.__lambda()
    end
    while j and is_lambda(j) do
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
    while is_lambda(s) do
        s = s.__lambda()
    end
    while is_lambda(pattern) do
        pattern = pattern.__lambda()
    end
    while init and is_lambda(init) do
        init = init.__lambda()
    end
    while plain and is_lambda(plain) do
        plain = plain.__lambda()
    end
    return sfind(s, pattern, init, plain)
end

local sgmatch = string.gmatch
string.gmatch = function (s, pattern)
    while is_lambda(s) do
        s = s.__lambda()
    end
    while is_lambda(pattern) do
        pattern = pattern.__lambda()
    end
    return sgmatch(s, pattern)
end

local sgsub = string.gsub
string.gsub = function (s, pattern, repl, n)
    while is_lambda(s) do
        s = s.__lambda()
    end
    while is_lambda(pattern) do
        pattern = pattern.__lambda()
    end
    while is_lambda(repl) do
        repl = repl.__lambda()
    end
    while n and is_lambda(n) do
        n = n.__lambda()
    end
    return sgsub(s, pattern, repl, n)
end

local slen = string.len
string.len = function (s)
    while is_lambda(s) do
        s = s.__lambda()
    end
    return slen(s)
end

local slower = string.lower
string.lower = function (s)
    while is_lambda(s) do
        s = s.__lambda()
    end
    return slower(s)
end

local smatch = string.match
string.match = function (s, pattern, init)
    while is_lambda(s) do
        s = s.__lambda()
    end
    while is_lambda(pattern) do
        pattern = pattern.__lambda()
    end
    while init and is_lambda(init) do
        init = init.__lambda()
    end
    return smatch(s, pattern, init)
end

local srep = string.rep
string.rep = function (s, n, sep)
    while is_lambda(s) do
        s = s.__lambda()
    end
    while is_lambda(n) do
        n = n.__lambda()
    end
    while sep and is_lambda(sep) do
        sep = sep.__lambda()
    end
    return srep(s, n, sep)
end

local sreverse = string.reverse
string.reverse = function (s)
    while is_lambda(s) do
        s = s.__lambda()
    end
    return sreverse(s)
end

local ssub = string.sub
string.sub = function (s, i, j)
    while is_lambda(s) do
        s = s.__lambda()
    end
    while is_lambda(i) do
        i = i.__lambda()
    end
    while j and is_lambda(j) do
        j = j.__lambda()
    end
    return ssub(s, i, j)
end

local supper = string.upper
string.upper = function (s)
    while is_lambda(s) do
        s = s.__lambda()
    end
    return supper(s)
end

-- test -----------------------------------------------------------------------

M.test = load_test and require"mad.lang.lambda.test.string" or {}


-- end ------------------------------------------------------------------------

return M
