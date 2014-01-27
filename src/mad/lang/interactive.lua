local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  mad.lang.interactive - Interactive mode
SYNOPSIS
  require"mad.lang.interactive".interactive(error_mapping_module)
DESCRIPTION
  Starts the interactive handler of mad. Will get the current parser and start
  parsing line by line. If a line is unfinished, it will prompt the user for
  another line until the input can be read as a chunk.
  Each finished line/multiple lines will be a single chunk, meaning that local
  values do not work between different chunks.
RETURN VALUES
  None
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
