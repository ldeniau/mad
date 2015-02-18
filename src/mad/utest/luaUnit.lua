local M = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.utest.LuaUnit
  
SYNOPSIS
  local lu = require'mad.utest.luaUnit'()
  lu:addModuleToTest(modname)
  lu:addFunctionToTest(modname,funname)
  lu:run()
  
DESCRIPTION
  Contains functions for running unit tests for several modules and 
  print statistics afterwards.
  
  luaUnit = require'mad.utest.luaUnit'
  lu = luaUnit()
    Initializes an instance of luaUnit, with its own statistics.
  lu:addModuleToTest(modname)
    Adds the module modname to the list of modules to be tested.
    A module can be added while the tests are being run, and will only
    be run once.
  lu:addFunctionToTest(modname,funname)
    Adds the function funname in the module modname to be tested.
    A function can be added while the tests are being run, and will
    only be run once. It will also not be run if the module modname
    is in the list of modules ot be run.
  lu:run()
    Runs all modules and function in it's list of modules to be run, 
    and displays the statistics.  
    
RETURN VALUES
  A table with call semantic to start an instance of luaUnit.

SEE ALSO
  mad.utest.UnitResult
  mad.utest.testObject

ACKNOWLEDGMENTS
  Based on LuaUnit (http://phil.freehackers.org/luaunit/),
  written by Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
  and updated by Philippe Fremy <phil@freehackers.org>.
  Released under the X11 license.

]]

-- require ---------------------------------------------------------------------
local UnitResult = require"mad.utest.UnitResult"
local testObject = require"mad.utest.testObject"

-- module ---------------------------------------------------------------------

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern).
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
local function strsplit(delimiter, text)
    local list = {}
    local pos = 1
    if string.find("", delimiter, 1) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while true do
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

local function runTestMethod(self,aName, aModuleInstance, aMethod, testObjectForModule)
    local ok, errorMsg
    self.result:startTest(aName, testObjectForModule)
    local function err_handler(e)
        return e..'\n'..debug.traceback()
    end
    ok, errorMsg = xpcall( function() return aMethod(aModuleInstance, testObjectForModule) end, err_handler )
    if not ok then
        errorMsg = string.match(errorMsg, "(.-)\n")
        self.result:addFailure( errorMsg )
    end
    self.result:endTest(testObjectForModule)
end

local function runTestMethodName( self, methodName, testInstance, testObjectForModule )
    local methodInstance = testInstance[methodName]
    if isFunction( testInstance.setUp) then
        testInstance:setUp()
    end
    self:runTestMethod(methodName, testInstance, methodInstance, testObjectForModule )
    if isFunction(testInstance.tearDown) then
        testInstance:tearDown()
    end
end

local function runTestModuleByName( self, aModuleName )
    local moduleInstance = require(aModuleName)
    if not moduleInstance then
        error( "No such module: "..aModuleName )
    elseif not moduleInstance.test then
        io.stdout:write( "Module: "..aModuleName.." does not have a test-member.\n")
        return
    end
    local testObjectForModule = testObject()
    self.result:startModule( aModuleName, testObjectForModule )
    for methodName, method in pairs(moduleInstance.test) do
        if isFunction(method) and isTestFunction(methodName) and methodName ~= "self" then
            self:runTestMethodName( methodName, moduleInstance.test, testObjectForModule )
        end
    end
    if moduleInstance.test.self then
        self:runTestMethod("self", moduleInstance.test, moduleInstance.test.self, testObjectForModule )
    end
end

local function addModuleToTest( self, modname )
    self.modulesToTest[modname] = true
    self.modulesToTestSize = self.modulesToTestSize+1
end

local function addFunctionToTest( self, modname, funname )
    if not self.modulesToTest[modname] then
        self.modulesToTest[modname] = { funname = true }
        self.modulesToTestSize = self.modulesToTestSize+1
    elseif type(self.modulesToTest[modname]) == "table" then
        self.modulesToTest[modname][funname] = true
        self.modulesToTestSize = self.modulesToTestSize+1
    end
end

local function testTable( self )
    for modname,v in pairs(self.modulesToTest) do
        if v and type(v) ~= "table" and not self.testedModules[modname] then
            self:runTestModuleByName( modname )
            self.testedModules[modname] = true
        elseif v and not self.testedModules[modname] then
            for fun,_ in pairs(v) do
                local moduleInstance = require(modname)
                local testObjectForModule = testObject()
                self.result:startModule( modname, testObjectForModule )
                self:runTestMethodName( fun, moduleInstance.test, testObjectForModule )
            end
        end
    end
end

local function run( self )
    while self.modulesToTestSize > 0 do
        self.modulesToTestSize = 0
        self:testTable()
    end
    return self.result:displayFinalResult()
end

local mt = {}; setmetatable(M, mt)

mt.__call = function (...)
    return {
        result = UnitResult(),
        modulesToTest = {},
        modulesToTestSize = 0,
        testedModules = {},
        addModuleToTest = addModuleToTest,
        addFunctionToTest = addFunctionToTest,
        runTestMethod = runTestMethod,
        runTestMethodName = runTestMethodName,
        runTestModuleByName = runTestModuleByName,
        run = run,
        testTable = testTable
    }
end

return M
