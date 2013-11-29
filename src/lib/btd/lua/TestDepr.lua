-----------------------------------------------------------------------------
-- Lua unit test runner.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
-- Based on LuaUnit.lua v1.3 under X11 License
-- see LICENSE.txt
--
-- @release 1.5.1 - 16 Feb 2009
-----------------------------------------------------------------------------
local lfs = require('lfs')
local Api = require('btd.lua.TestApi')

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.Test'}
local MT = {__index = M,__metatable = {}}

-----------------------------------------------------------------------------
-- Create instance
-- @return                      instance
-- @field   failures            number of failed test methods
-- @field   methods             number of test methods
-- @field   class               name of test class
-- @field   classes             list of test classes results
-- @field     fail              classes : class (at least one test) failed
-- @field     methods           classes : list of test methods results
-- @field       errorMsg        error message
-- @field       time            methods : test time
-- @field   method              name of test method
-- @field   time                recorded execution time of test suite
-- @field   errorIDE            error messages for IDE integration
-- @field   verbosity           verbosity level
-----------------------------------------------------------------------------
local function new()
  local m = {
    failures = 0,
    methods = 0,
    class = '',
    method = '',
    classes = {},
    tests = 0,
    time = 0,
    errorIDE = false,
    verbosity = 1
  }
  return setmetatable(m,MT)
end

-----------------------------------------------------------------------------
-- Run test method by name.
-- @param   methohdName     test method name (string)
-- @param   classInstance   test class (instance)
-- @usage                   runTestMethodName('TestToto:testToto',TestToto)
-----------------------------------------------------------------------------
local function runTestMethodName(self,methodName,classInstance)
  local environment,packages = {},{}
  for k,v in pairs(_G) do environment[k] = v end
  for k,v in pairs(package.loaded) do packages[k] = v end
  local methodInstance = loadstring(methodName..'()')
  self.method = methodName
  self.classes[self.class][methodName] = {}
  self.tests = self.tests + 1
  io.stdout:write('>>> '..methodName..'\n')
  if type(classInstance.setUp) == 'function' then classInstance:setUp() end
  local time = os.clock()
  local ok,errorMsg = xpcall(methodInstance,function (e)
    if self.errorIDE then
      -- remove 'stack traceback' and following lines
      return string.match(debug.traceback(string.gsub(e,'^(%.)',lfs.currentdir())),'(.-)stack traceback:.*')
    else
      -- remove 'xpcall' and 3 previous lines
      return string.match(debug.traceback(string.gsub(e,'^(%.)',lfs.currentdir())),"(.*)\n.-\n.-\n.-%[C%]: in function 'xpcall'.*")
    end
  end)
  self.classes[self.class][self.method].time = (os.clock() - time) * 1000
  io.stdout:write('Elapsed time '..self.classes[self.class][self.method].time..' ms\n')
  if not ok then
    self.failures = self.failures + 1
    self.classes[self.class].fail = true
    self.classes[self.class][self.method].errorMsg = errorMsg
    io.stdout:write((self.verbosity == 0) and 'F' or (self.errorIDE and 'Failed\n' or errorMsg..'\nFailed\n'))
  else
    io.stdout:write((self.verbosity == 0) and '.' or 'Ok\n')
  end
  if type(classInstance.tearDown) == 'function' then classInstance:tearDown() end
  for k,v in pairs(_G) do _G[k] = environment[k] end
  for k,v in pairs(package.loaded) do package.loaded[k] = packages[k] end
end

-----------------------------------------------------------------------------
-- Run test class by name.
-- @param   aClassName      test class (string)
-- @usage                   runTestClassByName('TestToto')
-----------------------------------------------------------------------------
local function runTestClassByName(self,aClassName)
  local environment,packages = {},{}
  for k,v in pairs(_G) do environment[k] = v end
  for k,v in pairs(package.loaded) do packages[k] = v end
  local methodName
  local hasMethod = string.find(aClassName,':')
  if hasMethod then
    methodName = string.sub(aClassName,hasMethod + 1)
    aClassName = string.sub(aClassName,1 ,hasMethod - 1)
  end
  local aBaseClassName = string.match(aClassName,'.*%.(.*)') or aClassName
  local ok,err = pcall(require,aClassName)
  if ok then err = '' else err = '\n'..err end
  local classInstance = assert(_G[aBaseClassName],'No such class: '..aClassName..err)
  self.class = aClassName
  if not self.classes[aClassName] then
    self.classes[aClassName] = {}
    self.classes[aClassName].fail = false
  end
  io.stdout:write('>>>>>>>>> '..aClassName..'\n')
  if type(classInstance.setUpClass) == 'function' then classInstance:setUpClass() end
  if hasMethod then
    assert(classInstance[methodName],'No such method: '..methodName)
    runTestMethodName(self,aBaseClassName..':'..methodName,classInstance)
  else
    local sortedClass = {}
    for methodName,_ in pairs(classInstance) do table.insert(sortedClass,methodName) end
    table.sort(sortedClass)
    for _,methodName in ipairs(sortedClass) do
      if type(classInstance[methodName]) == 'function' and string.sub(methodName,1,4) == 'test' then
        runTestMethodName(self,aBaseClassName..':'..methodName,classInstance)
      end
    end
  end
  if type(classInstance.tearDownClass) == 'function' then classInstance:tearDownClass() end
  io.stdout:write('\n')
  for k,v in pairs(_G) do _G[k] = environment[k] end
  for k,v in pairs(package.loaded) do package.loaded[k] = packages[k] end
end

-----------------------------------------------------------------------------
-- Run some specific test classes.
-- If no arguments are passed,run the class names specified on the
-- command line. If no class name is specified on the command line
-- run all classes whose name starts with 'Test'
-- If arguments are passed,they must be strings of the class names
-- that you want to run
-- @param   ...     tests to be run
-----------------------------------------------------------------------------
local function run(self,...)
  local time = os.clock()
  local environment,packages = {},{}
  for k,v in pairs(_G) do environment[k] = v end
  for k,v in pairs(package.loaded) do packages[k] = v end
  local testClassList = {}
  if #{...} > 0 then
    testClassList = {...}
  else
    testClassList = {}
    for class,_ in pairs(_G) do
      if string.sub(class,1,4) == 'Test' then table.insert(testClassList,class) end
    end
  end
  table.sort(testClassList)
  for _,testClass in ipairs(testClassList) do runTestClassByName(self,testClass) end
  self.time = (os.clock() - time) * 1000
  io.stdout:write('Total time '..self.time..' ms\n=========================================================\n')
  if self.failures > 0 then
    if not self.errorIDE then io.stdout:write('Failed tests :\n--------------\n') end
    local classesSorted = {}
    for k,_ in pairs(self.classes) do table.insert(classesSorted,k) end
    table.sort(classesSorted)
    for _,k in ipairs(classesSorted) do
      if self.classes[k].fail then
        local methodsSorted = {}
        for k2,_ in pairs(self.classes[k]) do
          if k2 ~= 'fail' then table.insert(methodsSorted,k2) end
        end
        table.sort(methodsSorted)
        for _,k2 in ipairs(methodsSorted) do
          if self.classes[k][k2].errorMsg then
            if self.errorIDE then
              io.stderr:write('Failed:'..string.match(self.classes[k][k2].errorMsg,'^(.-)\n')..k2..'\n'..string.match(self.classes[k][k2].errorMsg,'^.-\n(.*)'))
            else
              io.stdout:write('>>> '..k2..' failed\n'..self.classes[k][k2].errorMsg..'\n')
            end
          end
        end
      end
    end
    io.stdout:write('\n')
  end
  local failurePercent = (self.tests == 0) and 0 or 100 * self.failures / self.tests
  local successCount = self.tests - self.failures
  io.stdout:write(string.format('Success : %d%% - %d / %d\n',100 - math.ceil(failurePercent),successCount,self.tests))
  io.stdout:write('Total time '..self.time..' ms\n')
  for k,v in pairs(_G) do _G[k] = environment[k] end
  for k,v in pairs(package.loaded) do package.loaded[k] = packages[k] end
  return self.failures
end

-----------------------------------------------------------------------------
-- Clear test statistics.
-----------------------------------------------------------------------------
local function clear(self)
  self.failures = 0
  self.tests = 0
end

-----------------------------------------------------------------------------
-- Remove all TestXXX classes from the interpreter
-----------------------------------------------------------------------------
local function clearAll()
  for class,_ in pairs(_G) do
    if string.find(class,'Test') == 1 then
      package.loaded[class] = nil
      _G[class] = nil
    end
  end
end

-----------------------------------------------------------------------------
-- Help.
-----------------------------------------------------------------------------
local function help()
  io.stdout:write('btd.lua.Test - A xUnit tests module for Lua\n')
  io.stdout:write('command line switches :\n')
  io.stdout:write('- "-?" or "-h" or "-help" : this description\n')
  io.stdout:write('- "-e" : alternative error output format for IDE integration\n')
  io.stdout:write('- "-v" : verbosity on/off\n')
  io.stdout:write('\n')
  io.stdout:write('command line switches should come first on command line !\n')
end

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
setmetatable(M,{__call = new})
M.clear = clear
M.clearAll = clearAll
M.help = help
M.run = run

-----------------------------------------------------------------------------
-- Run when triggered from the command line
-----------------------------------------------------------------------------
if not arg or ('test.lua' ~= (string.match(string.lower(arg[0]),'.*%p(test.lua)$') or string.lower(arg[0]))) then
  return M
end
local m = new()
local start = 1
m.errorIDE = false
m.verbosity = 0
for i,v in ipairs(arg) do
  if v == '-?' or v == '-h' or v == '-help' then
    help()
    os.exit()
  elseif v == '-e' then
    m.errorIDE = true
    if i >= start then start = i + 1 end
  elseif v == '-v' then
    m.verbosity = 1
    if i >= start then start = i + 1 end
  end
end
m:run(unpack(arg,start))

