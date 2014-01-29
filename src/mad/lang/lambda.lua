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

-- global functions -----------------------------------------------------------

local is_lambda = function(a)
    return type(a) == "table" and a.__lambda
end

local g_tonumber = tonumber
_G.tonumber = function(a)
    if is_lambda(a) then
        a = a.__lambda()        
    end
    return g_tonumber(a)
end

_G.is_lambda = is_lambda

-- modules overloaded for the use of lambda -----------------------------------

require"mad.lang.lambda.math"
require"mad.lang.lambda.table"
require"mad.lang.lambda.string"

-- metamethods-----------------------------------------------------------------

local mt = {}

local Mcall = function(_, func )
    if type(func) ~= "function" then func = function() return func end end
    return setmetatable({ __lambda = func }, mt)
end
setmetatable(M,Mcall)

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

function M.test:self(ut)
    require"mad.core.unitTest".addModuleToTest"mad.lang.lambda.math"
    require"mad.core.unitTest".addModuleToTest"mad.lang.lambda.table"
    require"mad.core.unitTest".addModuleToTest"mad.lang.lambda.string"
end

local tbl1 = { __lambda = function() return 1 end }
setmetatable(tbl1, mt)
local tbl2 = { __lambda = function() return 1 end }
setmetatable(tbl2, mt)

print("tbl1 + 1", tbl1 + 1)
print("1 + tbl1", 1 + tbl1)
print("tbl1 + tbl2", tbl1 + tbl2)
print("1 + 2", 1+2)

print("tbl1 - 1", tbl1 - 1)
print("1 - tbl1", 1 - tbl1)
print("tbl1 - tbl2", tbl1 - tbl2)
print("1 - 2", 1-2)

print("tbl1 * 1", tbl1 * 1)
print("1 * tbl1", 1 * tbl1)
print("tbl1 * tbl2", tbl1 * tbl2)
print("1 * 2", 1 * 2)

print("tbl1 / 1", tbl1 / 1)
print("1 / tbl1", 1 / tbl1)
print("tbl1 / tbl2", tbl1 / tbl2)
print("1 / 2", 1 / 2)

print("tbl1 % 1", tbl1 % 1)
print("1 % tbl1", 1 % tbl1)
print("tbl1 % tbl2", tbl1 % tbl2)
print("1 % 2", 1 % 2)

print("tbl1 ^ 1", tbl1 ^ 1)
print("1 ^ tbl1", 1 ^ tbl1)
print("tbl1 ^ tbl2", tbl1 ^ tbl2)
print("1 ^ 2", 1 ^ 2)

print("-tbl1", -tbl1)

print("tbl1 < 1", tbl1 < 1)
print("1 < tbl1", 1 < tbl1)
print("tbl1 < tbl2", tbl1 < tbl2)
print("1 < 2", 1 < 2)

print("tbl1 > 1", tbl1 > 1)
print("1 > tbl1", 1 > tbl1)
print("tbl1 > tbl2", tbl1 > tbl2)
print("1 > 2", 1 > 2)

print("tbl1 <= 1", tbl1 <= 1)
print("1 <= tbl1", 1 <= tbl1)
print("tbl1 <= tbl2", tbl1 <= tbl2)
print("1 <= 2", 1 <= 2)

print("tbl1 >= 1", tbl1 >= 1)
print("1 >= tbl1", 1 >= tbl1)
print("tbl1 >= tbl2", tbl1 >= tbl2)
print("1 >= 2", 1 >= 2)

local tbl = {2,3,4}
local tbltbl = { __lambda = function () return tbl end }
setmetatable(tbltbl, mt)
print("tbltbl[1]", tbltbl[1])
print("tbltbl[2]", tbltbl[2])
print("tbltbl[3]", tbltbl[3])
print("tbltbl[4]", tbltbl[4])

tbltbl[1] = "one"
print("Should print one", tbltbl[1])
print("bonustest, should print one", tbl[1])

print("tbl1()", tbl1())

print("tbl1", tbl1)

print("tbl1==1", tbl1 == tbl2)

print("sin", math.sin(tbl1))

-- end ------------------------------------------------------------------------

return M
