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
__name = __name or {}

-- defs -----------------------------------------------------------------------

local defs = { }

defs._line = 0
defs._lastPos = 0
defs._maxPos = 0
local ch

function defs.savePos(_, pos)
    defs._lastPos = pos
    if pos > defs._maxPos then defs._maxPos = pos end
    return true
end

function defs.setup(str, pos)
    ch = {}
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
function defs.chunk( )
    ch.ast_id = 'block_stmt'
    return { ast_id = 'chunk', block = ch }
end

-- stmt

local chunknum = 1
function defs.stmtnum( str, pos, ... )
    local errors = require"mad.lang.errors"
    for _,v in ipairs{...} do
        table.insert(ch, v)
    end
    if defs._run then
        errors.setCurrentChunkName('chunkno'..chunknum)
        local gen = defs.genctor.getGenerator('lua')
        local code = gen:generate{ast_id = 'chunk', block = { ast_id = 'block_stmt', ... }, fileName = 'chunkno'..chunknum }
        local loadedCode, err = load(code, '@chunkno'..chunknum)
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
        chunknum = chunknum+1
    end
    return true
end

local seqedit


function defs.block( _, ... )
    return { ast_id = "block_stmt", line = defs._line, ... }
end

function defs.ifstmt( _, ...)
    return { ast_id = "if_stmt", line = defs._line, ... }
end

function defs.whilestmt( exp, block)
    return { ast_id = "while_stmt", line = defs._line, expr = exp, block = block }
end

function defs.assign( lhs, rhs )
    __name[lhs.name] = 'const'
    return { ast_id = 'assign', line = defs._line, lhs = {lhs}, rhs = {rhs} }
end

function defs.defassign( lhs, rhs )
    __name[lhs.name] = 'lambda'
    return { ast_id = 'assign', line = defs._line, lhs = {lhs}, 
            rhs = {
                { ast_id = 'fundef', kind = 'lambda', line = defs._line, param = {}, 
                block = 
                    { ast_id = 'block_stmt', { ast_id = 'ret_stmt', rhs } }
                }
                }
            }
end

local function sequenceAddition( name, class, ... )
    local attrtbl = { ast_id = 'tbldef'}
    local at, from
    for _,v in ipairs{...} do
        if v.kind and v.kind == 'name' and v.key.name == 'at' then
            at = v
        elseif v.kind and v.kind == 'name' and v.key.name == 'from' then
            from = v
            from.value = { ast_id = "literal", value = "'"..v.value.strname.."'" }
        else
            attrtbl[#attrtbl+1] = v
        end
    end
    return { ast_id = 'funcall', kind = ':', selfname = { ast_id = 'name', name = 'add' },
            name = seqedit,
            arg = {
                { ast_id = 'tbldef', 
                    { ast_id = 'tblfld', 
                    value = 
                        { ast_id = 'funcall', arg = {attrtbl},
                        name = 
                            { ast_id = 'funcall', arg = { { ast_id = 'literal', value = "'"..name.strname.."'" } }, name = class }
                        }
                    },
                    at,
                    at and from
                }
                }
            }
end

function defs.lblstmt ( name, class, ... ) -- ... = attrlist
    __name[name.name] = 'label'
    if seqedit then
        return sequenceAddition(name, class, ...) 
    end
    if class.name == 'sequence' then
        seqedit = name
    end
    return { ast_id = 'assign', line = defs._line,
            lhs = {
                name,
                },
            rhs = {
                { ast_id = 'funcall',
                name = 
                    { ast_id = 'funcall', name = class, arg = { { ast_id = 'literal', value = "'"..name.strname.."'" } } },
                arg =
                    {{ ast_id = 'tbldef', ... }}
                }
                }
            }
end

function defs.cmdstmt ( class, ... )
    if __name[class.name] == 'label' then -- it's an update
        return { ast_id = 'funcall', kind = ':',
                selfname = { ast_id = 'name', name = "set" },
                name = class, arg = { { ast_id = 'tbldef', ... } } }
    end
    if seqedit and class.name == "endsequence" then
        local name = seqedit
        seqedit = nil
        return { ast_id = 'funcall', kind = ":",
                name = name,
                selfname =
                    { ast_id = 'name', name = "done" },
                arg = {}
                }
    end
    return { ast_id = 'funcall', name = class,
            arg = {{ ast_id = 'tbldef', ... }} }
end

function defs.attr ( val )
    if val.ast_id == 'assign' then
        return { ast_id = 'tblfld', kind = 'name', key = val.lhs[1], value = val.rhs[1] }
    end
    return { ast_id = 'tblfld', value = val }
end

function defs.retstmt( _, ... )
    return { ast_id = 'ret_stmt', line = defs._line, ... }
end

function defs.macrocall(name, ...)
    local arg = { ast_id = 'tbldef' }
    for i,v in ipairs{...} do
        local nam
        if string.find(v,"$") == 1 then
            nam = { ast_id = 'name', name = string.sub(v,2) }
        else
            nam = { ast_id = 'literal', value = "[["..v.."]]" }
        end
        arg[i] = { ast_id = 'tblfld', value = { ast_id = 'funcall', name = { ast_id = 'name', name = 'tostring' }, arg = { nam } } }
    end
    return { ast_id = 'funcall', name = { ast_id = 'name', name = 'execmacro' }, arg = { { ast_id = 'name', name = name.name }, arg } }
end

function defs.macrodef(label, parlist, str)
    if not str then str = parlist parlist = {} end
    local par = {ast_id = "tbldef"}
    for i,v in ipairs(parlist) do
        par[i] = {}
        par[i].value = "'"..v.name.."'"
        par[i].ast_id = "literal"
    end
    return { ast_id = 'assign', lhs = { label }, rhs = { { ast_id = 'tbldef', { ast_id = 'tblfld', kind = 'name', key = { ast_id = 'name', name = 'str'}, value = { ast_id = 'literal', value = "[===["..str.."]===]" } }, { ast_id = 'tblfld', kind = 'name', key = { ast_id = 'name', name = 'par'}, value = par } } } }
end

function defs.parlist(...)
    return {...}
end

-- line
function defs.linestmt(lbl, line)
    return { ast_id = 'funcall', name = lbl, kind = ':', selfname = { ast_id = 'name', name = 'set' }, arg = {line} }
end

function defs.linector(...)
    return { ast_id = 'funcall', name = { ast_id = 'name', name = 'sequence' }, arg = { {ast_id = 'tbldef', ... } } }
end

function defs.linepart(line)
    return { ast_id = 'tblfld', value = line }
end

function defs.invertline(line)
    return { ast_id = 'expr', '-', line }
end

function defs.timesline(num, line)
    return { ast_id = 'expr', num, '*', line }
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

function defs.vector ( ... )
    return { ast_id = 'tbldef', line = defs._line, ... }
end

function defs.funcall(name, arguments)
    return { ast_id = 'funcall', line = defs._line, name = name, arg = arguments }
end

-- basic lexem

function defs.literal(val, val2)
    return { ast_id = 'literal', value = val2 or val, line = defs._line }
end

function defs.name(name)
    return { ast_id = 'name', name = translatename(name), strname = name, line = defs._line }
end


M.defs = defs

-- test suite -----------------------------------------------------------------------

M.test = require"mad.lang.madx.test.defs"

-- end ------------------------------------------------------------------------

return M
