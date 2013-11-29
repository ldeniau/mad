-----------------------------------------------------------------------------
-- GUI sequencer.
-- Executes a list of steps, should be called from the window managers idle
-- loop. As such this code is 'cross platform/window manager'.
-- Allthough the sequencer is ment for 'btd.lua.IupRobot' instructions, any
-- valid Lua instruction may be entered as a step. In the former case the
-- sequencer waits for the respective 'IupRobot' method to finish.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
--
-- @release 1.7.0 - 18 Apr 2009
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.GuiSequencer'}
local MT = {__index = M,__metatable = {}}

-----------------------------------------------------------------------------
-- Create instance
-- @return              instance
-- @return  ok          step ended
-- @field   step        step index
-- @field   stepSub     sub step index
-- @field   steps       list of robot steps and sub steps
-----------------------------------------------------------------------------
local function new(self)
  local m = {
    ok,
    step,
    stepSub,
    steps = {}
  }
  return setmetatable(m,MT)
end

-----------------------------------------------------------------------------
-- Append steps to sequencer.
-- It is allowed to enter multiple steps at the same time, these will be
-- executed in the order provided.
-- @param   func    sequence step(s)
-----------------------------------------------------------------------------
local function append(self,...)
  table.insert(self.steps,arg)
end

-----------------------------------------------------------------------------
-- Execute sequence.
-- @return      true while running
--              false otherwise
-----------------------------------------------------------------------------
local function execute(self)
  if self.step then
    if self.ok then
      if self.step == #self.steps then
        self.ok,self.step,self.stepSub = nil,nil,nil
        return false
      end
      self.ok = false
      self.step = self.step + 1
      self.stepSub = 1
    end
    if self.stepSub > #self.steps[self.step] then
      self.ok = true
      return true
    end
    local statement,waitFor = {}
    if self.steps[self.step][self.stepSub][1] == nil then
      for k,v in pairs(self.steps[self.step][self.stepSub]) do statement[k - 1] = v end
      waitFor = nil
    elseif type(self.steps[self.step][self.stepSub][1]) == 'function' then
      statement = self.steps[self.step][self.stepSub]
      waitFor = false
    elseif type(self.steps[self.step][self.stepSub][1]) == 'table' then
      for _,v in ipairs(self.steps[self.step][self.stepSub]) do table.insert(statement,v) end
      table.remove(statement,1)
      waitFor = nil
    else
      for _,v in ipairs(self.steps[self.step][self.stepSub]) do table.insert(statement,v) end
      waitFor = table.remove(statement,1)
    end
    local status,result = pcall(unpack(statement))
    if status then
      if waitFor == nil then
        self.stepSub = self.stepSub + 1
      elseif waitFor == false then
        if not result then self.stepSub = self.stepSub + 1 end
      elseif waitFor == true then
        if result then self.stepSub = self.stepSub + 1 end
      elseif waitFor == result then
        self.stepSub = self.stepSub + 1
      end
    else
      error('step '..self.step..' statement '..self.stepSub..'\n'..result,0)
    end
  else
    self.ok = false
    self.step = 1
    self.stepSub = 1
  end
  return true
end

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
setmetatable(M,{__call = new})
M.append = append
M.execute = execute
return M
