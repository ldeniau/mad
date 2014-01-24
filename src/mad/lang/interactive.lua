local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME

SYNOPSIS

DESCRIPTION

RETURN VALUES

SEE ALSO
]]

-- require --------------------------------------------------------------------
local lang = require"mad.lang"
local source = require"mad.lang.generator.source"

-- module ---------------------------------------------------------------------

local function getline()
    return io.read()
end

function M.interactive(errors)
    while true do
        local parser = lang.getParser(lang.getCurrentKey())
        local source = source(errors)
        io.stdout:write(">")
        local line = getline()
        if not line then break end
        local status, ast = pcall(parser.parse, parser, line, "stdin")
        while not status do
            if string.find(ast, "Unfinished rule") then
                io.stdout:write("\n>>")
                line = line.."\n"..getline()
                status, ast = pcall(parser.parse, parser, line, "stdin")
            else
                print(ast)
                break
            end
        end
        if status then
            local code = loadstring(source:generate(ast), "@stdin")
            local err,trace
            local status, result = xpcall(code, function(_err)
                err = _err
                trace = debug.traceback("",2)
                end)
            if not status then
                io.stderr:write(errors:handleError(err,trace).."\n")
                os.exit(-1)
            end
        end
    end
end

-- test suite -----------------------------------------------------------------
function M.test:setUp()
end

function M.test:tearDown()
end

-- end ------------------------------------------------------------------------

return M
