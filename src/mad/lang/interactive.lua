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



function M.interactive(errors)
    local lineNo, chunkNo = 0, 0
    local function getline()
        local line = io.read()
        if line then line = line..'\n' end
        lineNo = lineNo + 1
        return line
    end
    while true do
        chunkNo = chunkNo + 1
        local chunkname = 'stdin'..tostring(chunkNo)
        errors:setCurrentChunkName(chunkname)
        local parser = lang.getParser(lang.getCurrentKey(), lineNo)
        local source = source(errors)
        io.stdout:write(">")
        local line = getline()
        if not line then break end
        local status, ast = pcall(parser.parse, parser, line, "stdin")
        while not status do
            if string.find(ast, "Unfinished rule") then
                io.stdout:write('>>')
                line = line..getline()
                status, ast = pcall(parser.parse, parser, line, "stdin")
            else
                io.stderr:write(ast..'\n')
                break
            end
        end
        if status then
            local src = source:generate(ast)
            print("."..src..".")
            local code = loadstring(src, '@'..chunkname)
            local err,trace
            local status, result = xpcall(code, function(_err)
                err = _err
                trace = debug.traceback('',2)
                end)
            if not status then
                io.stderr:write(errors:handleError(err,trace)..'\n')
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
