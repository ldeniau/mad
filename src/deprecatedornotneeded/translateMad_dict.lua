#!/usr/bin/env luajit

local re = require"lib.lpeg.re"

local grammar = [=[
    main        <- (!'command_def' .)* 'command_def[]' s'='s readstrings s';' .*

    readstrings <- ((s'"' (command)* '"')                                               -> createTable
    command     <- (ident ss':' ss'=' ident^4 (attr (ss',' attr)*)? ss';')              -> command
    attr        <- (ident ss'=' ss'[' ident (ss',' default (ss',' default)?)? ss']')    -> attr
    default     <- ((ss'{' {|ident (ss',' ident)*|} ss'}') / ident )

-- basic lexems
    
    ident       <- ss {word}
    word        <- [^]%s,=;[:}{]*
    e           <- ![A-Za-z0-9_]
    num         <- [0-9]+
    sign        <- [-+]
    any         <- ch / nl
    ss          <- (ws ('"' s '"')?)*
    s           <- (ws / nl / cmt)*

    
-- comments

    cmt    <- ( (('//') ( ch* (nl/!.) )) / ('/*' (!'*/' any)* '*/' ) )

-- saving position
    sp     <- (''=>savePos)

]=]
-- escape characters, must be outside long strings
.. "ws <- [ \t\r]"
.. "ch <- [^\n]"
.. "nl <- [\n] -> newLine"

local function createTable ( ... )
    local val = {}
    for _,v in ipairs{...} do
        val[v.name] = v.value
    end
    return value = val
end

local function command ( name, ... )
    local val = {}
    for _,v in ipairs{...} do
        val[v.name] = v.value
    end
    return { name = name, value = val}
end

local function attr ( name, typ, absent, present )
    return { name = name, value = { type = typ, absent = absent, present = present, isarray = absent and type(absent) == 'table' } }
end

local parser = re.compile(grammar, {attr = attr, command = command, createTable = createTable})

function toLuaTable(filename)
    local file = assert(io.open(filename, 'r'))
	local str = file:read('*a')
	file:close()
	return parser:match(str)
end

local function writeTblToFile(tbl, file)
    if type(tbl) == 'table' then
        file:write'{'
        for k,v in pairs(tbl) do
            file:write(k)
            file:write'='
            writeTblToFile(v,file)
            file:write',\n'
        end
        file:write'}'
    else
        file:write(tbl)
    end
end

function toLuaFile(cFileName, luaFileName)
    local tbl = toLuaTable(cFileName)
    local file = assert(io.open(luaFileName, 'w'))
    writeTblToFile(tbl, file)
    file:flush()
    file:close()
end

toLuaFile(arg[1],arg[2])
