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

-- block and chunk

function defs.chunk( block )
    return { ast_id = "chunk", line = defs._line, block = 
                { ast_id = "block_stmt", 
                { ast_id = "assign", kind = "local",
                lhs = 
                    { ast_id = "name", name = "env"},
                rhs = 
                    { ast_id = "funcall", 
                    name = 
                        { ast_id = "name", name = "require" },
                    arg =
                        { { ast_id = "literal", value = '"mad.env"'} }
                    }
                },
                { ast_id = "assign", kind = "local",
                lhs = 
                    { ast_id = "name", name = "seq"},
                rhs = 
                    { ast_id = "funcall", 
                    name = 
                        { ast_id = "name", name = "require" },
                    arg =
                        { { ast_id = "literal", value = '"mad.sequence"'} }
                    }
                },
                block } }
end

-- stmt

function defs.assign( lhs, rhs )
    _M[lhs.name] = "const"
    return { ast_id = "assign", line = defs._line, lhs = lhs, rhs = rhs }
end

function defs.defassign( lhs, rhs )
    _M[lhs.name] = "lambda"
    return { ast_id = "assign", line = defs._line, lhs = lhs, 
            rhs = 
                { ast_id = "fundef", kind = "lambda", line = defs._line, param = {}, 
                block = 
                    { ast_id = "block_stmt", { ast_id = "ret_stmt", rhs } }
                }
            }
end

function defs.lblstmt ( name, class, ... ) -- ... = attrlist
    
end


function defs.retstmt( ... )
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
    return { ast_id = "name", name = name, line = defs._line }
end


M.defs = defs

-- test suite -----------------------------------------------------------------------

M.test = require"mad.lang.lua.test.defs"

-- end ------------------------------------------------------------------------

return M
