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
local context = require"mad.lang.context.context"

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
        error("Unexpected end of input while parsing file ")
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
            error("Unfinished rule on line "..tostring(line)..'\n'..strtbl[line])
        end
        local lasttok = string.match(str, '(%w+)', defs._maxPos)
        local errlineStart, errlineEnd = string.sub(strtbl[line],1,col-1), string.sub(strtbl[line],col)
        error("Unexpected token '"..lasttok.."' on line "..tostring(line)..'\n  -"'..errlineStart.."^"..errlineEnd..'"')
    end
end

-- block and chunk

function defs.chunk( block )
    return { ast_id = "chunk", line = defs._line, block = block }
end

function defs.block( _, ... )
    return { ast_id = "block_stmt", line = defs._line, ... }
end

-- stmt

function defs.breakstmt()
    return { ast_id = "break_stmt", line = defs._line }
end

function defs.gotostmt( label )
    return { ast_id = "goto_stmt", line = defs._line, name = label }
end

function defs.dostmt( block )
    block.kind = "do"
    return block
end

function defs.assign( lhs, rhs )
    return { ast_id = "assign", line = defs._line, lhs = lhs, rhs = rhs }
end

function defs.locassign( lhs, rhs )
    return { ast_id = "assign", line = defs._line, kind = "local", lhs = lhs, rhs = rhs }
end

function defs.whilestmt( exp, block)
    return { ast_id = "while_stmt", line = defs._line, expr = exp, block = block }
end

function defs.repeatstmt( block, exp )
    return { ast_id = "repeat_stmt", line = defs._line, expr = exp, block = block }
end

function defs.ifstmt( _, ...)
    return { ast_id = "if_stmt", line = defs._line, ... }
end

function defs.forstmt( name, first, last, step, block)
    if not block then block = step step = nil end
    return { ast_id = "for_stmt", line = defs._line, name = name, first = first, last = last, step = step, block = block }
end

function defs.forinstmt( names, exps, block )
    return { ast_id = "genfor_stmt", line = defs._line, name = names, expr = exps, block = block }
end

-- extra stmts

function defs.retstmt ( _, ... )
    return { ast_id = "ret_stmt", line = defs._line, ... }
end

function defs.label ( _, name )
    return { ast_id = "label_stmt", line = defs._line, name = name }
end

-- expressions

function defs.exp ( _, exp )
    exp.line = defs._line
    return exp
end

function defs.orexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.andexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.logexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
end

function defs.catexp( _, first, ... )
    if ... == nil then return first end
    return { ast_id = "expr", line = defs._line, first, ... }
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


local function createTreeFromListOfTableIndexAndCalls ( startnode, ... )
    local skip, ret, args = false, startnode, {...}
    for i = 1, #args, 2 do
        if not skip then
            if args[i] == ":" then
                ret = { ast_id = "funcall", line = defs._line, name = ret, selfname = args[i+1], arg = args[i+3], kind = ":" }
                skip = true
            elseif args[i] == "." then
                ret = { ast_id = "tblaccess" , line = defs._line, lhs = ret, rhs = args[i+1], kind = "." }
            elseif args[i] == "(" then
                ret = { ast_id = "funcall", line = defs._line, name = ret, arg = args[i+1] }
            elseif args[i] == "[" then
                ret = { ast_id = "tblaccess" , line = defs._line, lhs = ret, rhs = args[i+1] }
            end
        else
            skip = false
        end
    end
    return ret
end

function defs.varexp ( name, ... )
    return createTreeFromListOfTableIndexAndCalls( name, ... )
end

function defs.grpexp ( expr )
    return { ast_id = "grpexpr", line = defs._line, expr = expr }
end


-- variable definitions

function defs.vardef ( name, ... )
    return createTreeFromListOfTableIndexAndCalls( name, ... )
end

-- function definition

function defs.fundef_a ( params, body )
    return { ast_id = "fundef", line = defs._line, param = params, block = body }
end

function defs.fundef_n ( name, selfname, params, body )
    if selfname and selfname.ast_id ~= "name" then
        body = params
        params = selfname
        selfname = nil
    end
    return { ast_id = "fundef", line = defs._line, name = name, selfname = selfname, param = params, block = body }
end

function defs.fundef_l ( name, params, body )
    return { ast_id = "fundef", line = defs._line, kind = "local", name = name, param = params, block = body }
end

function defs.funname ( names, selfname )
    local ret = names[1]
    for i = 2, #names do
        ret = { ast_id = "tblaccess", line = defs._line, lhs = ret, rhs = names[i], kind = "." }
    end
    return ret, selfname
end

function defs.funparm ( names, ellipsis )
    if names.value and names.value == "..." then return {names} end
    names = names or {}
    table.insert(names, ellipsis)
    return names
end

function defs.funbody ( params, body )
    if not body then
        return nil, body
    end
    return params[1], body
end

function defs.funstmt ( name, ... )
    return createTreeFromListOfTableIndexAndCalls( name, ... )
end

function defs.funcall ( op, name, ... )
    if op == ":" then
        return op, name, "(", {...}
    elseif type(op) == "table" then
        return "(", { op, name, ... }
    else
        return "(", {}
    end    
end

function defs.lambda ( params, explist, exp )
    local ret
    if exp then
        ret = { ast_id = "ret_stmt", line = defs._line, exp }
    else
        ret = { ast_id = "ret_stmt", line = defs._line, table.unpack(explist) }
    end
    return { ast_id = "fundef", line = defs._line, param = params, block = { ast_id = "block_stmt", line = defs._line, ret } }
end

-- table

function defs.tabledef( _, ... )
    return { ast_id = "tbldef", line = defs._line, ... }
end

function defs.field( _, op, key, val )
    local kind = "expr"
    if not key then
        kind = nil
        val = op
        op = nil
    end
    if not val then
        kind = "name"
        val = key
        key = op
        op = nil
    end
    return { ast_id = "tblfld", key = key, value = val, kind = kind, line = defs._line }
end

function defs.tableidx( op, exp )
    return op, exp
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
