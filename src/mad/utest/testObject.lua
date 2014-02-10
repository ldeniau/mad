local M = { help = {}, test = {} }
local MT = {__index = M,__metatable = {}}
setmetatable(M,MT)

M.help.self = [[
NAME
  mad.utest.testObject
  
SYNOPSIS
  testObject:fails(function, [args]...)
  testObject:succeeds(function, [args]...)
  testObject:equals(actual, expected)
  testObject:differs(actual, expected)
  
DESCRIPTION
  Contains the functions to be used in the unit tests.
  The functions will be run by luaUnit and keep their own statistics within.
  
  All functions will raise startedCounter with 1 per run and raise
  succeedCounter with 1 after finishing without raising an error.
  
  testObject:fails(function, [args]...)
    Runs function with args and raises an error if function succeeded.
  testObject:succeeds(function, [args]...)
    Runs function with args and raises an error if function raised an error.
    Returns the functions return values if it succeeded.
  testObject:equals(actual, expected)
    Raises an error if actual differs from expected.
  testObject:differs(actual, expected)
    Raises an error if actual is equal to expected.

RETURN VALUES
  A table with a call semantic to set up an instance of testObject.

SEE ALSO
  mad.utest.luaUnit
  mad.utest.testObject

ACKNOWLEDGMENTS
  Based on LuaUnit (http://phil.freehackers.org/luaunit/),
  written by Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
  and updated by Philippe Fremy <phil@freehackers.org>.
  Released under the X11 license.

]]

local function fails(ut, f,...)
    ut.startedCounter = ut.startedCounter+1
    if not pcall(f,...) then ut.succeedCounter = ut.succeedCounter+1 return end
    error("No error generated",2)
end

local function succeeds(ut, f, ...)
    ut.startedCounter = ut.startedCounter+1
    local status = {pcall(f,...)}
    if status[1] then ut.succeedCounter = ut.succeedCounter+1 table.remove(status, 1) return table.unpack(status) end
    error("Error generated "..status[2],2)
end

local function equals(ut, actual,expected)
    ut.startedCounter = ut.startedCounter+1
    local nesting = ''
    local function equalsRec(actual,expected,key)
        local errorMsg = ''
        if type(actual) == 'table' and type(expected) == 'table' then
            if actual == expected then return errorMsg end
            for k,v in pairs(expected) do
                if actual[k] == nil then
                    errorMsg = errorMsg..nesting..'expected : key : '..tostring(k)..'\n'
                    errorMsg = errorMsg..nesting..'actual     : key : '..tostring(k)..' missing\n'
                else
                    errorMsg = errorMsg..equalsRec(actual[k],v,k)
                end
            end
            for k,v in pairs(actual) do
                if expected[k] == nil then
                    errorMsg = errorMsg..nesting..'expected : key : not expected\n'
                    errorMsg = errorMsg..nesting..'actual     : key : '..tostring(k)..'\n'
                end
            end
        elseif type(actual) ~= type(expected) then
            errorMsg = errorMsg..nesting..'expected : '..type(expected)..', actual '..type(actual)..'\n'
        elseif actual ~= expected then
                errorMsg = errorMsg..nesting..'expected : '..(key and 'table key '..key..' = ' or '')..(type(expected) == 'string' and "\n'"..expected.."'\n" or tostring(expected)..', ')
                errorMsg = errorMsg..nesting..'actual     : '..(key and 'table key '..key..' = ' or '')..(type(actual) == 'string' and "\n'"..actual.."'" or tostring(actual))..'\n'
        end
        return errorMsg
    end
    local errorMsg = equalsRec(actual,expected)
    if #errorMsg == 0 then ut.succeedCounter = ut.succeedCounter+1 return end
    error(errorMsg,2)
end

local function differs(ut, actual,expected)
    ut.startedCounter = ut.startedCounter+1
    local function differsRec(actual,expected,key)
        if type(actual) == 'table' and type(expected) == 'table' then
            for k,v in pairs(expected) do
                if actual[k] == nil or differsRec(actual[k],v,k) then return true end
            end
            for k,v in pairs(actual) do
                if expected[k] == nil then return true end
            end
        elseif type(actual) == 'table' or type(expected) == 'table' or actual ~= expected then
            return true
        end
        return false
    end
    if differsRec(actual,expected) then ut.succeedCounter = ut.succeedCounter+1 return end
    error('expected == actual',2)
end

MT.__call = function ()
    return {
        succeedCounter = 0,
        startedCounter = 0,
        differs = differs,
        equals = equals,
        fails = fails,
        succeeds = succeeds,
        trace = trace
    }
end

return M
