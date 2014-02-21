local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.madxenv

SYNOPSIS

DESCRIPTION

RETURN VALUES

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------

local sequence = require"mad.sequence"
local element  = require"mad.element"

-- module ---------------------------------------------------------------------

local global = _G
local madxenv = setmetatable({__name = {}}, { __index = function(tbl, key)
    if global[key] then return global[key] end
    if element[key] then return element[key] end
    if sequence[key] then return sequence[key] end
    if key == "sequence" then return sequence end
    return nil
end })

setfenv(0,madxenv)
_G = madxenv

__macrono = 1
function execmacro(macro, arg)
    local errors = require"mad.lang.errors"
    local defs = require"mad.lang.madx.defs".defs
    local par, str = macro.par, macro.str
    for i,v in ipairs(par) do
        str = string.gsub(str,v,arg[i] or '')
    end
    local lang = require"mad.lang"
	local parser = lang.getParser('madx', 0, false)
    local ast = parser:parse(str, 'macrono'..__macrono)
    errors.setCurrentChunkName('macrono'..__macrono)
    local gen = defs.genctor.getGenerator('lua')
    local code = gen:generate(ast)
    local loadedCode, err = load(code, '@macrono'..__macrono)
    __macrono = __macrono + 1
    if loadedCode then
        local status, result = xpcall(loadedCode, function(_err)
            err = _err
            trace = debug.traceback('',2)
        end)
        if not status then
            io.stderr:write(errors.handleError(err,trace)..'\n')
            os.exit(-1)
        end
    else
        error(err)
    end
end

pi      = math.pi
twopi   = 2*math.pi
degrad  = 180/pi
raddeg  = pi/180
e       = math.e
emass   = 0.510998928*10^-3
pmass   = 0.938272046
mumass  = 0.1056583715
clight  = 2.99792458*10^8
qelect  = 1.602176565*10^-19

sqrt    = math.sqrt
log     = math.log
log10   = function(x) return math.log(x,10) end
exp     = math.exp
sin     = math.sin
cos     = math.cos
tan     = math.tan
asin    = math.asin
acos    = math.acos
atan    = math.atan
sinh    = math.sinh
cosh    = math.cosh
tanh    = math.tanh
abs     = math.abs

ranf = math.random


-- end -------------------------------------------------------------------------
return M
