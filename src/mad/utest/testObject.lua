local M = { help = {}, test = {} }
local MT = {__index = M,__metatable = {}}
setmetatable(M,MT)

-----------------------------------------------------------------------------
-- Assert that calling f with the arguments will raise an error
-- @param     f             function under test
-- @param     ...         parameters to function onder test
-- @usage                     fails(f,1,2) => f(1,2) should generate an error
-----------------------------------------------------------------------------
local function fails(ut, f,...)
    ut.startedCounter = ut.startedCounter+1
    if not pcall(f,...) then ut.succeedCounter = ut.succeedCounter+1 return end
    error("No error generated",2)
end

-----------------------------------------------------------------------------
-- Assert that calling f with the arguments will not raise an error
-- @param     f             function under test
-- @param     ...         parameters to function onder test
-- @usage                     succeeds(f,1,2) => f(1,2) should not generate an error
-----------------------------------------------------------------------------
local function succeeds(ut, f, ...)
    ut.startedCounter = ut.startedCounter+1
    local status, ret = pcall(f,...)
    if status then ut.succeedCounter = ut.succeedCounter+1 return ret end
    error("Error generated "..ret,2)
end

-----------------------------------------------------------------------------
-- Assert that two values are equal and calls error else
-- @param     actual            result of test
-- @param     expected        expected result of test
-- @usage                             equals(1 + 1,2) => 1 + 1 = 2 ?
-----------------------------------------------------------------------------
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

-----------------------------------------------------------------------------
-- Assert that two values are different and calls error else
-- @param     actual            result of test
-- @param     expected        expected result of test
-- @usage                             differs(1 / 0,1) => 1 / 0 ~= 1 ?
-----------------------------------------------------------------------------
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

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------

return M
