--[[
Updated LuaUnit for use in MAD-framework.


        luaunit.lua

Description: A unit testing framework
Homepage: http://phil.freehackers.org/luaunit/
Initial author: Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
Lot of improvements by Philippe Fremy <phil@freehackers.org>
Version: 1.3
License: X11 License, see LICENSE.txt
]]--


-------------------------------------------------------------------------------
local UnitResult = require"mad.utest.UnitResult"
local testObject = require"mad.utest.testObject"

LuaUnit = {
    result = UnitResult
}

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern).
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
function LuaUnit.strsplit(delimiter, text)
    local list = {}
    local pos = 1
    if string.find("", delimiter, 1) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = string.find(text, delimiter, pos)
        if first then -- found?
            table.insert(list, string.sub(text, pos, first-1))
            pos = last+1
        else
            table.insert(list, string.sub(text, pos))
            break
        end
    end
    return list
end

function LuaUnit.isFunction(aObject)
    return 'function' == type(aObject)
end

function LuaUnit.isTestFunction(aFunctionName)
    return aFunctionName ~= "setUp" and aFunctionName ~= "tearDown"
end

function LuaUnit.strip_luaunit_stack(stack_trace)
    stack_list = LuaUnit.strsplit( "\n", stack_trace )
    strip_end = nil
    for i = #stack_list,1,-1 do
        if string.find(stack_list[i],"[C]: in function 'xpcall'",0,true)
            then
            strip_end = i - 2
        end
    end
    if strip_end then
        for i = strip_end, #stack_list do
            stack_list[i] = nil
        end
    end
    stack_trace = table.concat( stack_list, "\n" )
    return stack_trace
end

function LuaUnit:runTestMethod(aName, aClassInstance, aMethod, testObjectForClass)
    local ok, errorMsg
    LuaUnit.result:startTest(aName, testObjectForClass)
    local function err_handler(e)
        return e..'\n'..debug.traceback()
    end
    ok, errorMsg = xpcall( function() return aMethod(aClassInstance, testObjectForClass) end, err_handler )
    if not ok then
        errorMsg = string.match(errorMsg, "(.-)\n")
        LuaUnit.result:addFailure( errorMsg )
    end
    self.result:endTest(testObjectForClass)
end

function LuaUnit:runTestMethodName( methodName, testInstance, testObjectForClass )
    local methodInstance = testInstance[methodName]
    if self.isFunction( testInstance.setUp) then
        testInstance:setUp()
    end
    LuaUnit:runTestMethod(methodName, testInstance, methodInstance, testObjectForClass )
    if self.isFunction(testInstance.tearDown) then
        testInstance:tearDown()
    end
end

function LuaUnit:runTestClassByName( aClassName )
    local classInstance = require(aClassName)
    if not classInstance then
        error( "No such class: "..aClassName )
    elseif not classInstance.test then
        print( "Class: "..aClassName.." does not have a test-member." )
        return
    end
    local testObjectForClass = testObject()
    LuaUnit.result:startClass( aClassName, testObjectForClass )
    for methodName, method in pairs(classInstance.test) do
        if LuaUnit.isFunction(method) and LuaUnit.isTestFunction(methodName) and methodName ~= "self" then
            LuaUnit:runTestMethodName( methodName, classInstance.test, testObjectForClass )
        end
    end
    if classInstance.test.self then
        LuaUnit:runTestMethod("self", classInstance.test, classInstance.test.self, testObjectForClass )
    end
end

function LuaUnit:run(...)
    args={...}
    args = args[1]
    if #args > 0 then
        for _,className in pairs(args) do
            LuaUnit:runTestClassByName( className )
        end
    else
        error("NYI: This will have to be implemented once the tester has been properly implemented.",2)
    end
    return LuaUnit.result:displayFinalResult()
end

return LuaUnit
