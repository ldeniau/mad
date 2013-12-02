-----------------------------------------------------------------------------
-- Unit test runner.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
-- Based on LuaUnit.lua v1.3 under X11 License
-- see LICENSE.txt
--
-- @release 1.7.0 - 18 Apr 2009
-----------------------------------------------------------------------------
local lfs = require('lfs')
local lanes = require('lanes').configure{ protect_allocator = true }
local Api = require('btd.lua.TestApi')
local TestClass = require('btd.lua.TestClass')

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.Test'}
local MT = {__index = M,__metatable = {}}

-----------------------------------------------------------------------------
-- Create instance
-- @return              instance
-- @field   classes     list of test classes results
-- @field   errorIDE    error messages for IDE integration
-- @field   fail        test framework error (setUp, tearDown,...)
-- @field   failures    number of failed test methods
-- @field   ok          test result
-- @field   silent      don't report results
-- @field   source      'btd.lua.test:run' file name and line number
-- @field   tests       number of test methods
-- @field   time        recorded execution time of test suite
-- @field   verbose     verbose mode
-----------------------------------------------------------------------------
local function new()
  local m = {
    classes = {},
    errorIDE = false,
    fail = false,
    failures = 0,
    ok = true,
    silent = false,
    source,
    tests = 0,
    time,
    verbose = true
  }
  return setmetatable(m,MT)
end

-----------------------------------------------------------------------------
-- Report test results.
-----------------------------------------------------------------------------
local function report(self)
  local classes = {}
  for k,v in pairs(self.classes) do
    if not v.reported then
      table.insert(classes,k)
      v.reported = true
    end
  end
  if #classes == 0 then return end
  local title = '+ Results of running : '..self.source..' +'
  io.stdout:write('\n\n'..string.rep('+',#title)..'\n'..title..'\n'..string.rep('+',#title)..'\n')
  table.sort(classes)
  for _,v in ipairs(classes) do
    self.classes[v]:report(true,self.verbose,self.errorIDE)
  end
  if self.fail then
    io.stdout:write('\nFRAMEWORK FAILURES\n')
  elseif self.ok then
    io.stdout:write('\nOK\n')
  else
    io.stdout:write('\nFAILURES\n')
  end
  io.stdout:write('Total time '..self.time..' s\n=========================================================\n')
  if self.fail or not self.ok then
    if not self.errorIDE then io.stdout:write('Failed tests :\n--------------\n') end
    for _,v in ipairs(classes) do
      self.classes[v]:report(false,self.verbose,self.errorIDE)
    end
    io.stdout:write('\n')
  end
  if self.tests == 0 then
    io.stdout:write('No tests run\n')
  else
    io.stdout:write(string.format('Success : %d%% - %d / %d\n',math.ceil((1 - self.failures/self.tests) * 100),self.tests - self.failures,self.tests))
  end
  io.stdout:write('Total time '..self.time..' s\n')
  return self.failures
end

-----------------------------------------------------------------------------
-- Report all test results.
-----------------------------------------------------------------------------
local function reportAll(self)
  for k,v in pairs(self.classes) do v.reported = false end
  report(self)
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
  self.time = os.clock() - (self.time or 0)
  self.source = lfs.currentdir()..(string.match(lfs.currentdir(),'[\\/]') or '/')..debug.getinfo(2).short_src..':'..debug.getinfo(2).currentline..':'
  local testClassList = {}
  if #{...} > 0 then
    for _,v in ipairs({...}) do
      self.classes[v] = TestClass(v)
      --Just my thing
      for i, vi in pairs(v) do print(i,vi) end
      -- end of my thing
      self.classes[v].handle = self.classes[v]:lane()
    end
  else
    for k,_ in pairs(_G) do
      if string.sub(k,1,4) == 'Test' then
        self.classes[k] = TestClass(k)
        self.classes[k].handle = self.classes[k]:lane()
      end
    end
  end
  for _,v in pairs(self.classes) do
    if not v.finished then
      local result = v.handle[1]
      v:update(result)
      v.finished = true
      self.tests = self.tests + v.tests
      self.failures = self.failures + v.failures
      if v.fail then self.fail = true end
      if not v.ok then self.ok = false end
    end
  end
  self.time = os.clock() - self.time
  local time = os.clock()
  if not self.silent then report(self) end
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
M.report = report
M.reportAll = reportAll
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
m.verbosity = true
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
