UnitResult = { -- class
	failureCount = 0,
	testCount = 0,
	errorList = {},
	currentClassName = "",
	currentTestName = "",
	testHasFailure = false,
	verbosity = 0
}
function UnitResult:displayClassName()
	print( self.currentClassName )
end

function UnitResult:displayTestName()
	if self.verbosity > 0 then
		print( "\t".. self.currentTestName )
	end
end

function UnitResult:displayFailure( errorMsg )
	if self.verbosity == 0 then
		io.stdout:write("F")
	else
		print( errorMsg )
		print( 'Failed' )
	end
end

function UnitResult:displaySuccess()
	if self.verbosity > 0 then
		--print ("\tOk" )
	else
		io.stdout:write(".")
	end
end

function UnitResult:displayOneFailedTest( failure )
	testName, errorMsg = unpack( failure )
	print("\t"..testName.." failed")
	print( errorMsg )
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

function UnitResult:startTest(testName)
	self.currentTestName = testName
	self:displayTestName()
self.testCount = self.testCount + 1
	self.testHasFailure = false
end

function UnitResult:addFailure( errorMsg )
	self.failureCount = self.failureCount + 1
	self.testHasFailure = true
	table.insert( self.errorList, { self.currentTestName, errorMsg } )
	self:displayFailure( errorMsg )
end

function UnitResult:endTest()
	if not self.testHasFailure then
		self:displaySuccess()
	end
end

return UnitResult
