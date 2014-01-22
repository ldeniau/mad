local UnitResult = {help={},test={}}


local maxLength = 50

local function displayClassName( self )
    io.stdout:write( "["..self.currentClassName.."]\n" )
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
    print("\t"..testName.." failed")
    io.stdout:write("\t"..errorMsg.."\n")
end

local function displayFailedTests( self )
    if #self.errorList == 0 then return end
    print("Failed tests:")
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
    print( string.format("Success : %d%% - %d / %d",
        100-math.ceil(failurePercent), successCount, self.testCount) )
    return self.failureCount
  end

local function startClass( self, className)
    self.currentClassName = className
    self:displayClassName()
end

local function startTest( self, testName, testObjectForClass)
    self.currentTestName = testName
    self.testCount = self.testCount + 1
    self.startClock = os.clock()
    self.startStartedCounter = testObjectForClass.startedCounter
    self.startSucceedCounter = testObjectForClass.succeedCounter
    self.noFailed = #self.errorList
end

local function addFailure( self,  errorMsg )
    self.failureCount = self.failureCount + 1
    table.insert( self.errorList, { self.currentTestName, errorMsg } )
end

local function endTest( self, testObjectForClass)
    self.timeSpent = os.clock() - self.startClock
    self.testsStarted = testObjectForClass.startedCounter - self.startStartedCounter
    self.testsSucceeded = testObjectForClass.succeedCounter - self.startSucceedCounter
    self:displayTestName()
    self:displayTimeSpent()
    self:displayNumberOfSuccesses()
    self:displayPassOrFail()
    self:displayErrors()
end

local mt = {}; setmetatable(UnitResult, mt)

mt.__call = function (...)
	return {
	    displayClassName = displayClassName,
	    displayTestName = displayTestName,
	    displayTimeSpent = displayTimeSpent,
	    displayNumberOfSuccesses = displayNumberOfSuccesses,
	    displayPassOrFail = displayPassOrFail,
	    displayErrors = displayErrors,
	    displayOneFailedTest = displayOneFailedTest,
	    displayFailedTests = displayFailedTests,
	    displayFinalResult = displayFinalResult,
	    startClass = startClass,
	    startTest = startTest,
	    addFailure = addFailure,
	    endTest = endTest,
        failureCount = 0,
        testCount = 0,
        errorList = {},
        currentClassName = "",
        currentTestName = "",
        testHasFailure = false,
        verbosity = 0
    }
end

return UnitResult
