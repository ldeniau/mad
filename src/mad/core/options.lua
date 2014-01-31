local M = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.core.options
    
SYNOPSIS
  require"mad.core.options".process(stringFilledWithOptions)
  stringFilledWithOptions = [options] listOfFileNames
    
DESCRIPTION
  Reads the command line options and fills the options table.
  
  options.process(string)
    -Reads the string and sets values corresponding to the options.
    
  Options:
    -profiler "profilerArgs"   - Must be last option
    -utest "list of filenames" - starts unit tests of the files given.
    -dumpAst                   - dumps the AST of the parsed files
    -dumpSource                - dumps the created source code
    -interactive               - starts interactive mode once all files have been finished
    -i                         - same as -interactive
    -benchmark "list of names" - looks in mad.benchmark after a file with name and runs it.

RETURN VALUES
  The table of options
  options.files       - A list of files to be parsed and run
  options.utest       - A list of modules to be unit tested
  options.benchmark   - A list of modules to be benchmarked
  options.dumpAst     - Whether the AST should be printed or not
  options.dumpSource  - Whether the generated source code should be printed or not
  options.profile     - Whether the profiler is running or not
  options.interactive - Whether interactive mode should be started or not

SEE ALSO
  None
]]

-- require --------------------------------------------------------------------
-- metamethods ----------------------------------------------------------------
-- module ---------------------------------------------------------------------

M.files = {}

local function processUTest(arg)
    M.utest = {}
    if arg[1] and (#arg > 1 or string.find(arg[1], "%s")) then
        local index = string.find(arg[1], "%-")
        if not index or index ~= 1 then
            local utestNames = table.remove(arg,1)
            for name in string.gmatch(utestNames, "(%S+)") do
                M.utest[#M.utest + 1] = name
            end
        end
    end
    return arg
end

local function processProfiler(arg)
    local profilerArgs, output
    if arg[1] and (#arg > 1 or string.find(arg[1], "%s")) then
        if not index or index ~= 1 then
            profilerArgs = table.remove(arg,1)
            if arg[1] and (#arg > 1 or string.find(arg[1], "%s")) then
                output = table.remove(arg,1)
            end
        end
    end
    require"jit.p".start(profilerArgs, output)
end

local function processBenchmark(arg)
    M.benchmark = {}
    if arg[1] and (#arg > 1 or string.find(arg[1], "%s")) then
        local index = string.find(arg[1], "%-")
        if not index or index ~= 1 then
            local tobench = table.remove(arg,1)
            for name in string.gmatch(tobench, "(%S+)") do
                M.benchmark[#M.benchmark + 1] = name
            end
        end
    end
    return arg
end

local function processArgs(arg)
    local handlingArgs = true
    local index = string.find(arg[1], "%-")
    while index and index == 1 do
        local opt = table.remove(arg,1)
        if opt == "-utest" then
            load_test = true
            processUTest(arg)
        elseif opt == "-interactive" or opt == "-i" then
            M.interactive = true
        elseif opt == "-dumpAst" then
            M.dumpAst = true
        elseif opt == "-dumpSource" then
            M.dumpSource = true
        elseif opt == "-profile" then
            M.profile = true
            processProfiler(arg)
        elseif opt == "-benchmark" then
            M.benchmark = true
            processBenchmark(arg)
        else
            error("Unhandled argument "..opt)
        end
        if #arg == 0 then break end
        index = string.find(arg[1], "%-")
    end
    return arg
end

local function processFileNames(arg)
    for _,v in ipairs(arg) do
        M.files[#M.files+1] = v
    end
end

M.process = function(arg)
    local fileNameTable = processArgs(arg)
    processFileNames(fileNameTable)
end

-- end ------------------------------------------------------------------------
return M
