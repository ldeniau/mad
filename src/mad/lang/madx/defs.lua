local M = { help={}, test={} }

-- module ---------------------------------------------------------------------

M.help.self = [[
NAME
  luaMadKernel

SYNOPSIS
  local defsLuaMadKernel = require"mad.lang.parser.actions.luaMadKernel".actions

DESCRIPTION
  Returns the actions used by patternLuaMadKernel

RETURN VALUES
  The table of modules and services.

SEE ALSO
  None
]]

-- require ------------------------------------------------------------------
local tableUtil = require('lua.tableUtil')
local lower     = string.lower
                  require"mad.madxenv"
_M.__name = _M.__name or {}

-- defs -----------------------------------------------------------------------

local defs = { }

defs._line = 0
defs._lastPos = 0
defs._maxPos = 0

function defs.savePos(_, pos)
    defs._lastPos = pos
    if pos > defs._maxPos then defs._maxPos = pos end
    return true
end

function defs.setup(str, pos)
    local line = defs._line
    local ofs  = 0
    while ofs < pos do
        local a, b = string.find(str, "\n", ofs)
        if a then
            ofs = a + 1
            line = line + 1
        else
            break
        end
    end
    defs._line = line
    defs._lastPos = line
    defs._maxPos = line
    return true
end

function defs.newLine()
    defs._line = defs._line + 1
end

function defs.error(str, pos)
    local loc = string.sub(str, pos, pos)
    if loc == '' then
        error("Unexpected end of input while parsing file",2)
    else
        local strtbl = {}
        for val in string.gmatch(str,"([^\n]*)\n") do
            strtbl[#strtbl+1] = val
        end
        local line = 0
        local col = 0
        local ofs = 0
        for i = 1, #strtbl do
            col = defs._maxPos - ofs
            ofs = ofs + string.len(strtbl[i]) + 1
            line = i
            if ofs > defs._maxPos then
                break
            end
        end
        local _, stop = string.find(str, '%s*', defs._maxPos)
        if stop == string.len(str) then
            error("Unfinished rule on line "..tostring(line)..'\n'..strtbl[line],2)
        else
            local lasttok = string.match(str, '(%w+)', defs._maxPos) or string.match(str, '(.)', defs._maxPos)
            local errlineStart, errlineEnd = string.sub(strtbl[line],1,col-1), string.sub(strtbl[line],col)
            error("Unexpected token '"..(lasttok or '').."' on line "..tostring(line)..'\n  -"'..errlineStart.."^"..errlineEnd..'"',2)
        end
    end
end

local function translatename(name)
    name = string.gsub(name, '(_)', '__')
    name = string.gsub(name, '(%.)', '_')
    name = string.gsub(name, '($)', '')
    name = lower(name)
    return name
end

-- block and chunk
local ch = {}
function defs.chunk( )
    table.insert(ch,1, { ast_id = "assign", kind = "local",
    lhs = {
        { ast_id = "name", name = "env"},
        },
    rhs = {
        { ast_id = "funcall", 
        name = 
            { ast_id = "name", name = "require" },
        arg =
            { { ast_id = "literal", value = '"mad.madxenv"'} }
        }
        },
    })
    table.insert(ch,1, { ast_id = "assign", kind = "local",
    lhs = {
        { ast_id = "name", name = "seq"},
        },
    rhs = {
        { ast_id = "funcall", 
        name = 
            { ast_id = "name", name = "require" },
        arg =
            { { ast_id = "literal", value = '"mad.sequence"'} }
        }
        },
    })
    table.insert(ch,1, { ast_id = "assign", kind = "local",
    lhs = {
        { ast_id = "name", name = "elem"},
        },
    rhs = {
        { ast_id = "funcall", 
        name = 
            { ast_id = "name", name = "require" },
        arg =
            { { ast_id = "literal", value = '"mad.element"'} }
        }
        }
    })
    ch.ast_id = "block_stmt"
    return { ast_id = "chunk", block = ch }
end

-- stmt

function defs.safe( val, pos )
    return val, pos
end

function defs.stmt(_,_, val )
    table.insert(ch, val)
    return true
end

local seqedit = nil

function defs.assign( lhs, rhs )
    _M.__name[lhs.name] = "const"
    return { ast_id = "assign", line = defs._line, lhs = {lhs}, rhs = {rhs} }
end

function defs.defassign( lhs, rhs )
    _M.__name[lhs.name] = "lambda"
    return { ast_id = "assign", line = defs._line, lhs = {lhs}, 
            rhs = {
                { ast_id = "fundef", kind = "lambda", line = defs._line, param = {}, 
                block = 
                    { ast_id = "block_stmt", { ast_id = "ret_stmt", rhs } }
                }
                }
            }
end

local function sequenceAddition( name, class, ... )
    local attrtbl = { ast_id = "tbldef"}
    local at, from
    for _,v in ipairs{...} do
        if v.kind and v.kind == "name" and v.key.name == "at" then
            at = v
        elseif v.kind and v.kind == "name" and v.key.name == "from" then
            from = v
        else
            attrtbl[#attrtbl+1] = v
        end
    end
    return { ast_id = "expr",
                '+',
                { ast_id = "tbldef", 
                    { ast_id = "tblfld", 
                    value = 
                        { ast_id = "funcall", arg = {attrtbl},
                        name = 
                            { ast_id = "funcall", arg = { { ast_id = "literal", value = "'"..name.strname.."'" } }, name = class }
                        }
                    },
                    at,
                    at and from
                },
            }
end

function defs.lblstmt ( name, class, ... ) -- ... = attrlist
    _M.__name[name.name] = "label"
    if seqedit then
        return sequenceAddition(name, class, ...) 
    end
    if class.name == "sequence" then
        seqedit = name
    end
    return { ast_id = "assign", line = defs._line,
            lhs = {
                name,
                },
            rhs = {
                { ast_id = "funcall",
                name = 
                    { ast_id = "funcall", name = class, arg = { { ast_id = "literal", value = '"'..name.name..'"' } } },
                arg =
                    {{ ast_id = "tbldef", ... }}
                }
                }
            }
end

function defs.cmdstmt ( class, ... )
    if _M.__name[class.name] == "label" then -- it's an update
        return { ast_id = "funcall", kind = ':',
                selfname = { ast_id = "name", name = "set" },
                name = class, arg = { { ast_id = "tbldef", ... } } }
    end
    if seqedit and class.name == "endsequence" then
        local name = seqedit
        seqedit = nil
        return { ast_id = "funcall", kind = ":",
                name = name,
                selfname =
                    { ast_id = "name", name = "done" },
                arg = {}
                }
    end
    return { ast_id = "funcall", name = class,
            arg = {{ ast_id = "tbldef", ... }} }
end

function defs.attr ( val )
    if val.ast_id == "assign" then
        return { ast_id = "tblfld", kind = "name", key = val.lhs[1], value = val.rhs[1] }
    end
    return { ast_id = "tblfld", value = val }
end

function defs.retstmt( _, ... )
    return { ast_id = "ret_stmt", line = defs._line, ... }
end

-- expressions
function defs.exp ( _, exp )
    exp.line = defs._line
    return exp
end

function defs.sumexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.prodexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.unexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.powexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.grpexp ( expr )
    return { ast_id = "grpexpr", line = defs._line, expr = expr }
end

function defs.vector ( list )
    return { ast_id = "tbldef", line = defs._line, list }
end

function defs.funcall(name, arguments)
    return { ast_id = 'funcall', line = defs._line, name = name, arg = arguments }
end

-- basic lexem

function defs.literal(val)
    return { ast_id = "literal", value = val, line = defs._line }
end

function defs.name(name)
    return { ast_id = "name", name = translatename(name), strname = name, line = defs._line }
end


M.defs = defs

-- test suite -----------------------------------------------------------------------

M.test = require"mad.lang.lua.test.defs"

-- end ------------------------------------------------------------------------

return M