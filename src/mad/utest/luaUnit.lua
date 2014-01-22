--[[
Updated LuaUnit for use in MAD-framework.


        local function lua

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
local LuaUnit    = {}

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern).
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
local function strsplit(delimiter, text)
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

local function isFunction(aObject)
    return 'function' == type(aObject)
end

local function isTestFunction(aFunctionName)
    return aFunctionName ~= "setUp" and aFunctionName ~= "tearDown"
end

local function strip_luaunit_stack(stack_trace)
    stack_list = self.strsplit( "\n", stack_trace )
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

local function runTestMethod(self,aName, aClassInstance, aMethod, testObjectForClass)
    local ok, errorMsg
    self.result:startTest(aName, testObjectForClass)
    local function err_handler(e)
        return e..'\n'..debug.traceback()
    end
    ok, errorMsg = xpcall( function() return aMethod(aClassInstance, testObjectForClass) end, err_handler )
    if not ok then
        errorMsg = string.match(errorMsg, "(.-)\n")
        self.result:addFailure( errorMsg )
    end
    self.result:endTest(testObjectForClass)
end

local function runTestMethodName( self, methodName, testInstance, testObjectForClass )
    local methodInstance = testInstance[methodName]
    if isFunction( testInstance.setUp) then
        testInstance:setUp()
    end
    self:runTestMethod(methodName, testInstance, methodInstance, testObjectForClass )
    if isFunction(testInstance.tearDown) then
        testInstance:tearDown()
    end
end

local function runTestClassByName( self, aClassName )
    local classInstance = require(aClassName)
    if not classInstance then
        error( "No such class: "..aClassName )
    elseif not classInstance.test then
        print( "Class: "..aClassName.." does not have a test-member." )
        return
    end
    local testObjectForClass = testObject()
    self.result:startClass( aClassName, testObjectForClass )
    for methodName, method in pairs(classInstance.test) do
        if isFunction(method) and isTestFunction(methodName) and methodName ~= "self" then
            self:runTestMethodName( methodName, classInstance.test, testObjectForClass )
        end
    end
    if classInstance.test.self then
        self:runTestMethod("self", classInstance.test, classInstance.test.self, testObjectForClass )
    end
end

local function addModuleToTest( self, modname )
    self.modulesToTest[modname] = true
end

local function addFunctionToTest( self, modname, funname )
    if not self.modulesToTest[modname] then
        self.modulesToTest[modname] = { funname = true }
    elseif type(self.modulesToTest[modname]) == "table" then
        self.modulesToTest[modname][funname] = true
    end        
end

local function run( self, mod, fun )
    
    for modname,v in pairs(self.modulesToTest) do
        if v and type(v) ~= "table" and not self.testedModules[modname] then
            self:runTestClassByName( modname )
            self.testedModules[modname] = true
        else
            for fun,_ in pairs(v) do
                local classInstance = require(modname)
                local testObjectForClass = testObject()
                self.result:startClass( modname, testObjectForClass )
                self:runTestMethodName( fun, classInstance.test, testObjectForClass )
            end
        end
    end

    return self.result:displayFinalResult()
end

local mt = {}; setmetatable(LuaUnit, mt)

mt.__call = function (...)
    return {
        result = UnitResult(),
        modulesToTest = {},
        testedModules = {},
        addModuleToTest = addModuleToTest,
        runTestMethod = runTestMethod,
        runTestMethodName = runTestMethodName,
        runTestClassByName = runTestClassByName,
        run = run
    }
end

--[[local function run(...)
    args={...}
    args = args[1]
    if #args > 0 then
        for _,className in pairs(args) do
            self:runTestClassByName( className )
        end
    else
        error("NYI: This will have to be implemented once the tester has been properly implemented.",2)
    end
    return self.result:displayFinalResult()
end]]

return LuaUnit
