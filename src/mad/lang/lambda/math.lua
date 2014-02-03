local M  = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.lambda.math

SYNOPSIS
  Overloads the math-library to work with the lambda function

DESCRIPTION
  All functions are overloaded to call the lambda function with no arguments if
  it is received as an argument.
  lambda = { __lambda = func }
    math.xxx( lambda ) -> math.xxx( lambda.__lambda() )
  Exceptions:
    math.max/math.min won't work with deferred calls

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
local is_lambda = is_lambda

-- module ---------------------------------------------------------------------


local mabs = math.abs
math.abs = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mabs(x)
end

local macos = math.acos
math.acos = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return macos(x)
end

local masin = math.asin
math.asin = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return masin(x)
end

local matan = math.atan
math.atan = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return matan(x)
end

local matan2 = math.atan2
math.atan2 = function(y, x)
    while x and is_lambda(x) do
        x = x.__lambda()
    end
    while is_lambda(y) do
        y = y.__lambda()
    end
    return matan2(y, x)
end

local mceil = math.ceil
math.ceil = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mceil(x)
end

local mcos = math.cos
math.cos = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mcos(x)
end

local mcosh = math.cosh
math.cosh = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mcosh(x)
end

local mdeg = math.deg
math.deg = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mdeg(x)
end

local mexp = math.exp
math.exp = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mexp(x)
end

local mfloor = math.floor
math.floor = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mfloor(x)
end

local mfmod = math.fmod
math.fmod = function(x, y)
    while is_lambda(x) do
        x = x.__lambda()
    end
    while y and is_lambda(y) do
        y = y.__lambda()
    end
    return y and mfmod(x, y) or mfmod(x)
end

local mfrexp = math.frexp
math.frexp = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mfrexp(x)
end

local mldexp = math.ldexp
math.ldexp = function(m, e)
    while is_lambda(m) do
        m = m.__lambda()
    end
    while e and is_lambda(e) do
        e = e.__lambda()
    end
    return e and mldexp(m, e) or mldexp(m)
end

local mlog = math.log
math.log = function(x, base)
    while is_lambda(x) do
        x = x.__lambda()
    end
    while base and is_lambda(base) do
        base = base.__lambda()
    end
    return base and mlog(x, base) or mlog(x)
end

local mmodf = math.modf
math.modf = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mmodf(x)
end

local mpow = math.pow
math.pow = function(x, y)
    while is_lambda(x) do
        x = x.__lambda()
    end
    while is_lambda(y) do
        y = y.__lambda()
    end
    return mpow(x, y)
end

local mrad = math.rad
math.rad = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mrad(x)
end

local mrandom = math.random
math.random = function(m, n)
    while m and is_lambda(m) do
        m = m.__lambda()
    end
    while n and is_lambda(n) do
        n = n.__lambda()
    end
    return m and (n and mrandom(m, n) or mrandom(m)) or mrandom()
end

local mrandomseed = math.randomseed
math.randomseed = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    mrandomseed(x)
end

local msin = math.sin
math.sin = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return msin(x)
end

local msinh = math.sinh
math.sinh = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return msinh(x)
end

local msqrt = math.sqrt
math.sqrt = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return msqrt(x)
end

local mtan = math.tan
math.tan = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mtan(x)
end

local mtanh = math.tanh
math.tanh = function(x)
    while is_lambda(x) do
        x = x.__lambda()
    end
    return mtanh(x)
end

-- test -----------------------------------------------------------------------

M.test = load_test and require"mad.lang.lambda.test.math" or {}

function M.test:setUp()
    self.lambda = require"mad.lang.lambda"
    self.abs = mabs
    self.acos = macos
    self.asin = masin
    self.atan = matan
    self.atan2 = matan2
    self.ceil = mceil
    self.cos = mcos
    self.cosh = mcosh
    self.deg = mdeg
    self.exp = mexp
    self.floor = mfloor
    self.fmod = mfmod
    self.frexp = mfrexp
    self.ldexp = mldexp
    self.log = mlog
    self.max = mmax
    self.min = mmin
    self.modf = mmodf
    self.pow = mpow
    self.rad = mrad
    self.random = mrandom
    self.randomseed = mrandomseed
    self.sin = msin
    self.sinh = msinh
    self.sqrt = msqrt
    self.tan = mtan
    self.tanh = mtanh
end

function M.test:tearDown()
    self.lambda = nil
    self.abs = nil
    self.acos = nil
    self.asin = nil
    self.atan = nil
    self.atan2 = nil
    self.ceil = nil
    self.cos = nil
    self.cosh = nil
    self.deg = nil
    self.exp = nil
    self.floor = nil
    self.fmod = nil
    self.frexp = nil
    self.ldexp = nil
    self.log = nil
    self.max = nil
    self.min = nil
    self.modf = nil
    self.pow = nil
    self.rad = nil
    self.random = nil
    self.randomseed = nil
    self.sin = nil
    self.sinh = nil
    self.sqrt = nil
    self.tan = nil
    self.tanh = nil
end

-- end ------------------------------------------------------------------------

return M
