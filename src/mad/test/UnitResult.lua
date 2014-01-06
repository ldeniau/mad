UnitResult = { -- class
	failureCount = 0,
	testCount = 0,
	errorList = {},
	currentClassName = "",
	currentTestName = "",
	testHasFailure = false,
	verbosity = 0
}

local maxLength = 50

function UnitResult:displayClassName()
	io.stdout:write( "["..self.currentClassName.."]\n" )
end

function UnitResult:displayTestName()
	io.stdout:write( "  "..self.currentTestName )
end

function UnitResult:displayTimeSpent()
	for i = string.len(self.currentTestName) + 2, maxLength - 20 do
		io.stdout:write(" ")
	end
	io.stdout:write("( "..string.format("%.2f",self.timeSpent).."s ) ")
end

function UnitResult:displayNumberOfSuccesses()
	io.stdout:write(self.testsSucceeded.."/"..self.testsStarted)
end

function UnitResult:displayPassOrFail()
	if self.testsSucceeded == self.testsStarted and self.testsSucceeded > 0 then
		io.stdout:write(": PASS\n")
	else
		io.stdout:write(": FAILED\n")
	end
end

function UnitResult:displayErrors()
	if #self.errorList == 0 then return end	
	for i = self.noFailed+1, #self.errorList do
		io.stdout:write("\t"..self.errorList[i][2].."\n")
	end
end


function UnitResult:displayOneFailedTest( failure )
	testName, errorMsg = unpack( failure )
	print("\t"..testName.." failed")
	io.stdout:write("\t"..errorMsg.."\n")
end

function UnitResult:displayFailedTests()
	if table.getn( self.errorList ) == 0 then return end
	print("Failed tests:")
	for _,v in ipairs(self.errorList) do
		self:displayOneFailedTest(v)
	end
end

function UnitResult:displayFinalResult()
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

function UnitResult:startClass(className)
	self.currentClassName = className
	self:displayClassName()
end

function UnitResult:startTest(testName, testObjectForClass)
	self.currentTestName = testName
	self.testCount = self.testCount + 1
	self.startClock = os.clock()
	self.startStartedCounter = testObjectForClass.startedCounter
	self.startSucceedCounter = testObjectForClass.succeedCounter
	self.noFailed = #self.errorList
end

function UnitResult:addFailure( errorMsg )
	self.failureCount = self.failureCount + 1
	table.insert( self.errorList, { self.currentTestName, errorMsg } )
end

function UnitResult:endTest(testObjectForClass)
	self.timeSpent = os.clock() - self.startClock
	self.testsStarted = testObjectForClass.startedCounter - self.startStartedCounter
	self.testsSucceeded = testObjectForClass.succeedCounter - self.startSucceedCounter
	self:displayTestName()
	self:displayTimeSpent()
	self:displayNumberOfSuccesses()
	self:displayPassOrFail()
	self:displayErrors()
end

return UnitResult
