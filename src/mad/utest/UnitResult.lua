local M = { help = {}, test = {} }

M.help.self = [[
NAME
  mad.utest.UnitResult
  
SYNOPSIS
  local result = require'mad.utest.UnitResult'()
  result:startModule(moduleName, testObject)
  result:startTest(name, testObject)
  result:endTest(testObject)
  result:addFailure(errMsg)
  result:displayFinalResult()
  
DESCRIPTION
  local ur = require'mad.utest.UnitResult'
  result = ur()
    Sets up an instance of UnitResult
  result:startModule(moduleName, testObject)
    Updates the UnitResult-instance for testing of a new module.
    testObject is the modules corresponding mad.utest.testObject.
  result:startTest(name, testObject)
    Sets up the testObject to start a single test function.
    testObject is the modules corresponding mad.utest.testObject.
  result:endTest(testObject)
    Finished the current test and gathers all necessary statistics.
    testObject is the modules corresponding mad.utest.testObject.
  result:displayFinalResult()
    Displays the result of the tests that's been run.
RETURN VALUES
  A table with a call semantic to set up an instance of UnitResult

SEE ALSO
  mad.utest.luaUnit
  mad.utest.testObject
  
ACKNOWLEDGMENTS
  Based on LuaUnit (http://phil.freehackers.org/luaunit/),
  written by Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
  and updated by Philippe Fremy <phil@freehackers.org>.
  Released under the X11 license.

]]

local maxLength = 50

local function displayModuleName( self )
    io.stdout:write( "["..self.currentModuleName.."]\n" )
end

local function displayTestName( self )
    io.stdout:write( "  "..self.currentTestName )
end

local function displayTimeSpent( self )
    for i = string.len(self.currentTestName) + 2, maxLength - 24 do
        io.stdout:write(" ")
    end
    io.stdout:write("( "..string.format("%.2f",self.timeSpent).."s ) ")
end

local function displayNumberOfSuccesses( self )
    if self.testsSucceeded < 10 then
        io.stdout:write("  "..self.testsSucceeded.."/")
    elseif self.testsSucceeded < 100 then
        io.stdout:write(" "..self.testsSucceeded.."/")
    else
        io.stdout:write(self.testsSucceeded.."/")
    end
    if self.testsStarted < 10 then
        io.stdout:write(self.testsStarted.."  ")
    elseif self.testsStarted < 100 then
        io.stdout:write(self.testsStarted.." ")
    else
        io.stdout:write(self.testsStarted)
    end
end

local function displayPassOrFail( self )
    if self.testsSucceeded == self.testsStarted and self.testsSucceeded > 0 then
        io.stdout:write(": PASS\n")
    else
        io.stdout:write(": FAIL\n")
    end
end

local function displayErrors(self)
    if #self.errorList == 0 then return end    
    for i = self.noFailed+1, #self.errorList do
        io.stdout:write("\t"..self.errorList[i][2].."\n")
    end
end

local function displayOneFailedTest( self,  failure )
    testName, errorMsg = unpack( failure )
    io.stdout:write("\t"..testName.." failed\n")
    io.stdout:write("\t"..errorMsg.."\n")
end

local function displayFailedTests( self )
    if #self.errorList == 0 then return end
    io.stdout:write("Failed tests:\n")
    for _,v in ipairs(self.errorList) do
        self:displayOneFailedTest(v)
    end
end

local function displayFinalResult( self )
    self:displayFailedTests()
    local failurePercent, successCount
    if self.testCount == 0 then
        failurePercent = 0
    else
        failurePercent = 100 * self.failureCount / self.testCount
    end
    successCount = self.testCount - self.failureCount
    io.stdout:write( string.format("Success : %d%% - %d / %d\n",
        100-math.ceil(failurePercent), successCount, self.testCount) )
    return self.failureCount
  end

local function startModule( self, moduleName)
    self.currentModuleName = moduleName
    self:displayModuleName()
end

local function startTest( self, testName, testObjectForModule)
    self.currentTestName = testName
    self.testCount = self.testCount + 1
    self.startClock = os.clock()
    self.startStartedCounter = testObjectForModule.startedCounter
    self.startSucceedCounter = testObjectForModule.succeedCounter
    self.noFailed = #self.errorList
end

local function addFailure( self,  errorMsg )
    self.failureCount = self.failureCount + 1
    table.insert( self.errorList, { self.currentTestName, errorMsg } )
end

local function endTest( self, testObjectForModule)
    self.timeSpent = os.clock() - self.startClock
    self.testsStarted = testObjectForModule.startedCounter - self.startStartedCounter
    self.testsSucceeded = testObjectForModule.succeedCounter - self.startSucceedCounter
    self:displayTestName()
    self:displayTimeSpent()
    self:displayNumberOfSuccesses()
    self:displayPassOrFail()
    self:displayErrors()
end

local mt = {}; setmetatable(M, mt)

mt.__call = function (...)
	return {
	    displayModuleName = displayModuleName,
	    displayTestName = displayTestName,
	    displayTimeSpent = displayTimeSpent,
	    displayNumberOfSuccesses = displayNumberOfSuccesses,
	    displayPassOrFail = displayPassOrFail,
	    displayErrors = displayErrors,
	    displayOneFailedTest = displayOneFailedTest,
	    displayFailedTests = displayFailedTests,
	    displayFinalResult = displayFinalResult,
	    startModule = startModule,
	    startTest = startTest,
	    addFailure = addFailure,
	    endTest = endTest,
        failureCount = 0,
        testCount = 0,
        errorList = {},
        currentModuleName = "",
        currentTestName = "",
        testHasFailure = false,
        verbosity = 0
    }
end

return M
