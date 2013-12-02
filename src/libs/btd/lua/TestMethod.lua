-- when available in Lua Lanes use finaliser function together with debug.getinfo for maximum time error message

-----------------------------------------------------------------------------
-- Lua unit test method runner.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
-- Based on LuaUnit.lua v1.3 under X11 License
-- see LICENSE.txt
--
-- @release 1.7.0 - 18 Apr 2009
-----------------------------------------------------------------------------
local lanes = require('lanes')
local lfs = require('lfs')

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.TestMethod'}
local MT = {__index = M,__metatable = {}}

-----------------------------------------------------------------------------
-- Create instance
--
-- @param   base        base test class name
-- @param   class       test class name
-- @param   method      name of test method
-- @return              instance
-- @field   abort       abort testing flag
-- @field   base        base test class name
-- @field   class       test class name
-- @field   fail        test framework error (setUp, tearDown,...)
-- @field   finished    test method processing finished
-- @field   handle      lua lanes handle
-- @field   maxTime     maximum run time test method
-- @field   message     error or result message
-- @field   method      name of test method
-- @field   ok          test result
-- @field   serial      run test method exclusive (in set of serial methods)
-- @field   setUp       test method set up code
-- @field   source      test class path, line number 1
-- @field   started     test method processing started
-- @field   tearDown    test method tear down code
-- @field   time        test time
-----------------------------------------------------------------------------
local function new(self,class,base,method)
  local m = {
    abort,
    base = base,
    class = class,
    fail,
    finished,
    handle,
    maxTime,
    message,
    method = method,
    ok,
    serial,
    setUp,
    source,
    started,
    tearDown,
    time
  }
  return setmetatable(m,MT)
end

-----------------------------------------------------------------------------
-- Report test results
--
-- @param   all         report all results
-- @param   ide         IDE error message format
-- @param   verbose     verbose
-----------------------------------------------------------------------------
local function report(self,all,verbose,ide)
  local method = self.class..':'..self.method
  if self.abort then
    if all and verbose then
      io.stdout:write('>>> '..method..'\nElapsed time '..self.time..' s\nAborted\n')
    end
  elseif self.fail then
    if ide then
      if all and verbose then
        io.stdout:write('>>> '..method..'\nElapsed time '..self.time..' s\nFramework failed\n')
      elseif not all then
        local pre,post = string.match(self.message,'^(.-:%d-:)\n(.-)\n*$')
        if pre then
          io.stderr:write('Failed:'..pre..' '..method..'\n'..post..'\n\n')
        else
          io.stderr:write('Failed:'..self.source..' '..method..'\nABORT >> '..self.message..'\n\n')
        end
      end
    else
      if all and verbose then
        io.stdout:write('>>> '..method..'\nElapsed time '..self.time..' s\nFramework failed\n')
      elseif not all then
        io.stdout:write('>>> '..method..'\nElapsed time '..self.time..' s\nFramework failed\n'..self.message..'\n')
      end
    end
  elseif self.ok then
    if all and verbose then
      io.stdout:write('>>> '..method..'\nElapsed time '..self.time..' s\nOk\n')
    end
  else
    if ide then
      if all and verbose then
        io.stdout:write('>>> '..method..'\nElapsed time '..self.time..' s\nFailed\n')
      elseif not all then
        local message = string.match(self.message,'(.-)\nstack traceback:.*')
        local pre,post = string.match(message,'^(.-:%d-:)\n(.-)\n*$')
        if pre then
          io.stderr:write('Failed:'..pre..' '..method..'\n'..post..'\n\n')
        else
          io.stderr:write('Failed:'..self.source..' '..method..'\nABORT >> '..message..'\n\n')
        end
      end
    else
      if all and verbose or not all then
        -- remove 'xpcall' and 3 previous lines
        io.stdout:write('>>> '..method..'Elapsed time '..self.time..' s\nFailed\n'..(string.match(self.message,'(.*)\n.-\n.-\n.-%[C%]: in function "xpcall".*') or self.message)..'\n')
      end
    end
  end
end

-----------------------------------------------------------------------------
-- Update with test results
--
-- @param   method      results of test method
-----------------------------------------------------------------------------
local function update(self,method)
  self.fail = method.fail
  self.message = method.message
  self.ok = method.ok
  self.source = method.source
  self.time = method.time
end

-----------------------------------------------------------------------------
-- Run test method.
-- @return      test results
-----------------------------------------------------------------------------
function run(self,abort,finished,serial)
  if self.finished then return abort,finished,serial end
  if not self.started and self.serial and abort then
    self.abort = true
    self.finished = true
    self.maxTime = _G[self.base][self.method..'Time']
    self.started = true
    self.time = 0
    return abort,finished,serial
  end
  if not self.started and (not self.serial or not serial) then
    self.handle = self:lane()
    self.maxTime = _G[self.base][self.method..'Time']
    self.started = true
    self.time = os.clock()
    if self.serial then serial = true end
  end
  if self.started and not self.finished then
    finished = false
    if self.maxTime and os.clock() > (self.time + self.maxTime) then
      self.handle:cancel(0,true)
      self.time = os.clock() - self.time
      self.source = package.loaded['btd.lua.TestApi'].trace,self.source-- must be replaced by information from finaliser method
      self.message =  self.source..'\nexpected < '..self.maxTime..'s\nactual   = '..self.time..'s\ntimed out'
      self.ok = false
      if self.serial then
        serial = false
        if not self.ok then abort = true end
      end
      self.finished = true
      io.stdout:write('f')
    else
      local result,err,stack = self.handle:join(0)
      if result then
        self:update(result)
        if self.serial then
          serial = false
          if self.fail or not self.ok then abort = true end
        end
        self.finished = true
      end
    end
  end
  return abort,finished,serial
end

-----------------------------------------------------------------------------
-- Generate test method lane.
-- @return      test results
-----------------------------------------------------------------------------
local lane = lanes.gen('*',function(self)
  local ok,err = pcall(require,self.class)
  if not ok then self.fail = true; self.message = string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir()); self.time = 0; io.stdout:write('f'); return self end
  self.source = package.loaded['btd.lua.TestApi'].trace,self.source
  local methodInstance = _G[self.base][self.method]
  if not methodInstance then self.fail = true; self.message = self.source..'\nno such method'; self.time = 0; io.stdout:write('f'); return self end
  if self.setUp then
    local ok,err = pcall(self.setUp,self)
    if not ok then self.fail = true; self.message = string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir()); self.time = 0; io.stdout:write('e'); return self end
  end
  self.time = os.clock()
  local ok,err = xpcall(function() methodInstance(self) end,function(err) return debug.traceback(string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir())) end)
  self.time = os.clock() - self.time
  if self.tearDown then
    local ok,err = pcall(self.tearDown,self)
    if not ok then self.fail = true; self.message = string.gsub(string.gsub(err,'(:%d+:) ','%1\n',1),'^(%.)',lfs.currentdir()); io.stdout:write('e'); return self end
  end
  self.ok = ok
  if self.ok then
    self.message = 'Ok'
    io.stdout:write('o')
  else
    self.message = err
    io.stdout:write('f')
  end
  return self
end)

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
setmetatable(M,{__call = new})
M.lane = lane
M.report = report
M.run = run
M.update = update
return M
