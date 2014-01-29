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


local mabs = math.abs
_G.math.abs = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mabs(x)
end

local macos = math.acos
_G.math.acos = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return macos(x)
end

local masin = math.asin
_G.math.asin = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return masin(x)
end

local matan = math.atan
_G.math.atan = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return matan(x)
end

local matan2 = math.atan2
_G.math.atan2 = function(y, x)
    if x and is_lambda(x) then
        x = x.__lambda()
    end
    if is_lambda(y) then
        y = y.__lambda()
    end
    return matan2(y, x)
end

local mceil = math.ceil
_G.math.ceil = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mceil(x)
end

local mcos = math.cos
_G.math.cos = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mcos(x)
end

local mcosh = math.cosh
_G.math.cosh = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mcosh(x)
end

local mdeg = math.deg
_G.math.deg = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mdeg(x)
end

local mexp = math.exp
_G.math.exp = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mexp(x)
end

local mfloor = math.floor
_G.math.floor = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mfloor(x)
end

local mfmod = math.fmod
_G.math.fmod = function(x, y)
    if is_lambda(x) then
        x = x.__lambda()
    end
    if y and is_lambda(y) then
        y = y.__lambda()
    end
    return mfmod(x, y)
end

local mfrexp = math.frexp
_G.math.frexp = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mfrexp(x)
end

local mldexp = math.ldexp
_G.math.ldexp = function(m, e)
    if is_lambda(m) then
        m = m.__lambda()
    end
    if e and is_lambda(e) then
        e = e.__lambda()
    end
    return mldexp(m, e)
end

local mlog = math.log
_G.math.log = function(x, base)
    if is_lambda(x) then
        x = x.__lambda()
    end
    if base and is_lambda(base) then
        base = base.__lambda()
    end
    return mlog(x, base)
end

local mmax = math.max
_G.math.max = function(x, ...)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mmax(x, ...)
end

local mmin = math.min
_G.math.min = function(x, ...)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mmin(x, ...)
end

local mmodf = math.modf
_G.math.modf = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mmodf(x)
end

local mpow = math.pow
_G.math.pow = function(x, y)
    if is_lambda(x) then
        x = x.__lambda()
    end
    if is_lambda(y) then
        y = y.__lambda()
    end
    return mpow(x, y)
end

local mrad = math.rad
_G.math.rad = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mrad(x)
end

local mrandom = math.random
_G.math.random = function(m, n)
    if m and is_lambda(m) then
        m = m.__lambda()
    end
    if n and is_lambda(n) then
        n = n.__lambda()
    end
    return mrandom(m, n)
end

local mrandomseed = math.randomseed
_G.math.randomseed = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mrandomseed(x)
end

local msin = math.sin
_G.math.sin = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return msin(x)
end

local msinh = math.sinh
_G.math.sinh = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return msinh(x)
end

local msqrt = math.sqrt
_G.math.sqrt = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return msqrt(x)
end

local mtan = math.tan
_G.math.tan = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mtan(x)
end

local mtanh = math.tanh
_G.math.tanh = function(x)
    if is_lambda(x) then
        x = x.__lambda()
    end
    return mtanh(x)
end

-- test -----------------------------------------------------------------------



-- end ------------------------------------------------------------------------

return M
