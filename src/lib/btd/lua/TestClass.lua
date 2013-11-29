-----------------------------------------------------------------------------
-- Lua unit test class runner.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
-- Based on LuaUnit.lua v1.3 under X11 License
-- see LICENSE.txt
--
-- @release 1.7.0 - 18 Apr 2009
-----------------------------------------------------------------------------
local lfs = require('lfs')
local lanes = require('lanes')
local TestMethod = require('btd.lua.TestMethod')

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.TestClass'}
local MT = {__index = M,__metatable = {}}

-----------------------------------------------------------------------------
-- Create instance
--
-- @param   class       name of test class
-- @return              instance
-- @field   abort       abort set of serial methods upon failure
-- @field   base        base test class name
-- @field   class       test class name
-- @field   fail        test framework error (setUp, tearDown,...)
-- @field   failures    number of failed test methods
-- @field   finished    test class processing finished
-- @field   handle      lua lanes handle
-- @field   ok          test result
-- @field   reported    test class reporting finished
-- @field   serial      run test method exclusive (in set of serial methods)
-- @field   source      test class path, line number 1
-- @field   tests       number of test methods
-- @field   time        test time
-- @field   methods     list of test methods results
-----------------------------------------------------------------------------
local function new(self,class)
  local m = {
    abort,
    base,
    class = class,
    fail,
    failures = 0,
    finished,
    handle,
    message,
    method,
    ok,
    source,
    serial,
    tests = 0,
    time,
    methods = {},
  }
  return setmetatable(m,MT)
end

-----------------------------------------------------------------------------
-- Report test results
--
-- @param   all         report all results
-- @param   ide         IDE error message format
-----------------------------------------------------------------------------
local function report(self,all,verbose,ide)
  if all and verbose or (not all and not ide and (self.fail or not self.ok)) then
    io.stdout:write('>>>>>>>>> '..self.class..'\n')
  end
  local methods = {}
  for k,_ in pairs(self.methods) do table.insert(methods,k) end
  table.sort(methods)
  for _,v in ipairs(methods) do
    self.methods[v]:report(all,verbose,ide)
  end
  if self.fail then
    if all and verbose or not all and not ide then
      io.stdout:write('<<<<<<<<< Framework failed\n'..(self.message or 'method failed')..'\n')
    end
  elseif self.ok then
    if all and verbose then
      io.stdout:write('<<<<<<<<< Ok\n')
    end
  else
    if all and verbose or not all and not ide then
      io.stdout:write('<<<<<<<<< Failed\n')
    end
  end
end

-----------------------------------------------------------------------------
-- Update with test results
--
-- @param   class       results of test class
-----------------------------------------------------------------------------
local function update(self,class)
  self.fail = class.fail
  self.failures = class.failures
  self.message = class.message
  self.ok = class.ok
  self.source = class.source
  self.tests = class.tests
  self.time = class.time
  for k,v in pairs(class.methods) do
    self.methods[k] = TestMethod(k)
    for k2,v2 in pairs(v) do
      self.methods[k][k2] = v2
    end
  end
end

-----------------------------------------------------------------------------
-- Generate test class.
-- @return      test results
-----------------------------------------------------------------------------
local lane = lanes.gen('*',function(self)
  local method = string.match(self.class,'.-:(.*)')
  self.class = string.match(self.class,'(.-):.*') or self.class
  self.base = string.match(self.class,'.*%.(.*)') or self.class
  local ok,err = pcall(require,self.class)
  if not ok then self.fail = true; self.message = string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir()); self.time = 0; io.stdout:write('F'); return self end
  local source = package.loaded['btd.lua.TestApi']
  if not source then
    local separator = string.match(lfs.currentdir(),'[\\/]') or '/'
    self.source = lfs.currentdir()..separator..string.gsub(self.class,'%.',separator)
    self.fail = true; self.message = self.source..'\nmissing require("btd.lua.TestApi")';self.time = 0; io.stdout:write('E'); return self
  end
  self.source = source.trace
  local classInstance = _G[self.base]
  if not classInstance then self.fail = true; self.message = self.source..'\nno such class'; self.time = 0; io.stdout:write('F'); return self end
  self.abort = _G[self.base].Abort
  self.serial = _G[self.base].Serial
  if type(classInstance.setUpClass) == 'function' then
    local ok,err = pcall(classInstance.setUpClass)
    if not ok then self.fail = true; self.message = string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir()); self.time = 0; io.stdout:write('E'); return self end
  end
  self.time = os.clock()
  if method then
    self.methods[method] = TestMethod(self.class,self.base,method)
  else
    for k,_ in pairs(classInstance) do
      if type(classInstance[k]) == 'function' and string.sub(k,1,4) == 'test' then self.methods[k] = TestMethod(self.class,self.base,k) end
    end
  end
  local setUp = type(classInstance.setUp) == 'function' and classInstance.setUp
  local tearDown = type(classInstance.setUp) == 'function' and classInstance.tearDown
  for _,v in pairs(self.methods) do
    self.tests = self.tests + 1
    v.serial = self.serial or _G[self.base][v.method..'Serial']
    v.setUp = setUp
    v.tearDown = tearDown
  end
  local methods = {}
  for k,_ in pairs(self.methods) do table.insert(methods,k) end
  table.sort(methods)
  local abort,finished,serial
  repeat
    finished = true
    for _,v in ipairs(methods) do
      abort,finished,serial = self.methods[v]:run(abort,finished,serial)
      abort = abort and self.abort
    end
  until finished == true
  self.time = os.clock() - self.time
  self.ok = true
  for _,v in pairs(self.methods) do
    if v.fail then self.fail = true end
    if not v.ok then
      self.ok = false
      self.failures = self.failures + 1
    end
  end
  if type(classInstance.tearDownClass) == 'function' then
    local ok,err = pcall(classInstance.tearDownClass)
    if not ok then self.fail = true; self.message = string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir()); io.stdout:write('E'); return self end
  end
  if self.fail then io.stdout:write('E') elseif self.ok then io.stdout:write('O') else io.stdout:write('F') end
  return self
end)

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
setmetatable(M,{__call = new})
M.report = report
M.lane = lane
M.update = update
return M

