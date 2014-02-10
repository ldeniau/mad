local M  = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.lambda

SYNOPSIS
  lambda = require'mad.lang.lambda'
  
  _G.is_lambda(tbl)
  _G.tonumber(x[,base])

DESCRIPTION
  When required, tables with type(tbl.__lambda) == 'function' will
  be read as a lambda-function.
  Lambda-functions have their metatable overloaded, to allow for lazy evaluation
  if the function doesn't need arguments.
  
  Operators and functions supporting lazy evaluation of lambdas:
  +,
  -(unary and binary),
  *,
  /,
  ..,
  %,
  ^,
  <=,
  >=,
  <,
  >,
  #,
  pairs,
  ipairs,
  tostring,
  index,
  newindex.
  
  Some functions in math, string and table also support lazy evaluation.

RETURN VALUES
  A table with tests and help.

SEE ALSO
  mad.lang.lambda.math
  mad.lang.lambda.string
  mad.lang.lambda.table
]]

-- global functions -----------------------------------------------------------

local is_lambda = function(a)
    return a and type(a) == "table" and a.__lambda and type(a.__lambda) == "function" or false
end

local g_tonumber = tonumber
_G.tonumber = function(a, b)
    if is_lambda(a) then
        a = a.__lambda()        
    end
    if b and is_lambda(b) then
        b = b.__lambda()        
    end
    return g_tonumber(a, b)
end

_G.is_lambda = is_lambda

-- modules overloaded for the use of lambda -----------------------------------

require"mad.lang.lambda.math"
require"mad.lang.lambda.table"
require"mad.lang.lambda.string"

-- metamethods-----------------------------------------------------------------

local mt = {}

setmetatable(M, { __call = function(_, func )
    local func1
    if type(func) ~= "function" then
        func1 = function() return func end
    end
    func1 = func1 or func
    return setmetatable({ __lambda = func1 }, mt)
end })

local eval = function(lhs,rhs)
    if type(lhs) == "table" and lhs.__lambda then
        lhs = lhs.__lambda()        
    end
    if type(rhs) == "table" and rhs.__lambda then
        rhs = rhs.__lambda()        
    end
    return lhs, rhs
end

mt.__add = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs+rhs
end

mt.__sub = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs-rhs
end

mt.__mul = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs*rhs
end

mt.__div = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs/rhs
end

mt.__mod = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs%rhs
end

mt.__pow = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs^rhs
end

mt.__unm = function(lhs)
    return -lhs.__lambda()
end

mt.__concat = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs..rhs
end

mt.__len = function(lhs)
    return #lhs.__lambda()
end

mt.__lt = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs<rhs
end

mt.__le = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs<=rhs
end

mt.__index = function(lhs, key)
    return lhs.__lambda()[key]
end

mt.__newindex = function(lhs, key, val)
    lhs.__lambda()[key] = val
end

mt.__call = function(lhs, ...)
    return lhs.__lambda(...)
end

mt.__tostring = function(lhs)
    return tostring(lhs.__lambda())
end

mt.__ipairs = function(lhs)
    return ipairs(lhs.__lambda())
end

mt.__pairs = function(lhs)
    return pairs(lhs.__lambda())
end

mt.__eq = function(lhs, rhs)
    lhs, rhs = eval(lhs, rhs)
    return lhs==rhs
end

-- test -----------------------------------------------------------------------

M.test = load_test and require"mad.lang.test.lambda" or {}

-- end ------------------------------------------------------------------------

return M
