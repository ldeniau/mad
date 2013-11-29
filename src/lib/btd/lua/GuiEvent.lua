-----------------------------------------------------------------------------
-- GUI event methods.
-- Methods to programmatically move the cursor, click it's buttons or press
-- keys on the keyboard.
--
-- Remark :
-- - convenience wrapper for some "_GuiEvent.c" methods
-- - actions are inserted in the display managers event queue. To give it time
--   to process them action confirmation is delayed 'wait' time.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
--
-- @release 1.7.1 - 7 Feb 2010
-----------------------------------------------------------------------------
require("_GuiEvent")

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.GuiEvent'}
local MT = {__index = M,__metatable = {}}

-----------------------------------------------------------------------------
-- Create instance.
--
-- @param   update      update time interval
-- @param   wait        wait for event queue processing
-- @return              instance
-- @field   demo        show cursor path
-- @field   height      screen height in pixels
-- @field   width       screen width in pixels
-- @field   timeBeg     operation begin time
-- @field   timeEnd     operation end time
-- @field   timeNext    operation next processing time
-- @field   update      update time interval (minimum 0.02 s)
-- @field   wait        wait for event queue processing (minimum 0.1 s)
-----------------------------------------------------------------------------
local function new(self,width,height,update,wait)
  local m = {
    demo,
    width = width,
    height = height,
    timeBeg,
    timeEnd,
    timeNext,
    update = update or 0.02,
    wait = wait or 0.1
  }
  return setmetatable(m,MT)
end

-----------------------------------------------------------------------------
-- Click left mouse button.
--
-- @param   time        time to hold button (in seconds)
-- @return              true while click is active
--                      false if click finished
-----------------------------------------------------------------------------
local function leftClick(self,time)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    if self.timeNext >= self.timeEnd + self.wait then
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
    self.timeNext = self.timeEnd + self.wait
    _GuiEvent.leftUp()
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + (self.demo and time or 0)
    self.timeNext = self.timeEnd
    _GuiEvent.leftDown()
  end
  return true
end

-----------------------------------------------------------------------------
-- Double click left mouse button.
--
-- @param   time        time to hold button (in seconds)
-- @return              true while click is active
--                      false if click finished
-----------------------------------------------------------------------------
local function leftClickDbl(self,time)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    if self.timeNext >= self.timeEnd + self.wait then
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
    if self.timeNext >= self.timeEnd then
      self.timeNext = self.timeEnd + self.wait
      _GuiEvent.leftUp()
    else
      self.timeNext = self.timeEnd
      _GuiEvent.leftUp()
      _GuiEvent.leftDown()
    end
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + (self.demo and time or 0)
    self.timeNext = (self.timeBeg + self.timeEnd)/2
    _GuiEvent.leftDown()
  end
  return true
end

-----------------------------------------------------------------------------
-- Press left mouse button.
--
-- @return              true while press is active
--                      false if press finished
-----------------------------------------------------------------------------
local function leftDown(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.leftDown()
  end
  return true
end

-----------------------------------------------------------------------------
-- Release left mouse button.
--
-- @return              true while release is active
--                      false if release finished
-----------------------------------------------------------------------------
local function leftUp(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.leftUp()
  end
  return true
end

-----------------------------------------------------------------------------
-- Move cursor from current to desired position in the designated time.
--
-- Remark
-- Confirmation that the cursor position is reached is delayed by 'wait'
-- to give the OS time to process the event queue.
--
-- @param   x           desired X position (in pixels)
-- @param   y           desired Y position (in pixels)
-- @param   xCur        current X position (in pixels)
-- @param   yCur        current Y position (in pixels)
-- @param   time        time in which to make the displacement (in seconds)
-- @return              true while moving
--                      false if movement finished
-----------------------------------------------------------------------------
local function goto(self,x,y,xCur,yCur,time)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    if self.timeNext >= self.timeEnd + self.wait then
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
    if self.timeNext >= self.timeEnd then
      self.timeNext = self.timeEnd + self.wait
      _GuiEvent.moveAbs(x * 65535 / self.width,y * 65535 / self.height)
    else
      self.timeNext = self.timeNext + self.update
      local timeRem = self.timeEnd - os.clock()
      _GuiEvent.moveAbs((xCur + (x - xCur) * self.update / timeRem) * 65535 / self.width,(yCur + (y - yCur) * self.update / timeRem) * 65535 / self.height)
    end
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + (self.demo and time or 0)
    self.timeNext = self.timeBeg
  end
  return true
end

-----------------------------------------------------------------------------
-- Move cursor to middle of screen element.
-- From element top left coordinates and width and height the center of the
-- screen element is calculated and used as a destination for the mouse
-- movement.
--
-- @param   element     IUP element destination
-- @param   time        time in which to make the displacement
-- @return              true while moving
--                      false if movement finished
-----------------------------------------------------------------------------
local function gotoCenter(self,element,time)
  local width,height = string.match(element.rastersize,'(.-)x(.*)')
  return goto(self,element.x + width/2,element.y + height/2,time)
end

-----------------------------------------------------------------------------
-- Click 'normal' key.
--
-- @param   key         key to click
-- @param   time        time to hold key (in seconds)
-- @return              true while click is active
--                      false if click finished
-----------------------------------------------------------------------------
local function keyClick(self,key,time)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    if self.timeNext >= self.timeEnd + self.wait then
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
    self.timeNext = self.timeEnd + self.wait
    _GuiEvent.keyUp(key)
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + (self.demo and time or 0)
    self.timeNext = self.timeEnd
    _GuiEvent.keyDown(key)
  end
  return true
end

-----------------------------------------------------------------------------
-- Output string of 'normal' keys.
--
-- @param   string      output string
-- @param   time        time to hold key (in seconds)
-- @return              true while click is active
--                      false if click finished
-----------------------------------------------------------------------------
local function keyString(self,string)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    if self.timeNext >= self.timeEnd then
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    for i = 1,string.len(string) do
      _GuiEvent.keyDown(string.sub(string,i,i))
      _GuiEvent.keyUp(string.sub(string,i,i))
    end
  end
  return true
end

-----------------------------------------------------------------------------
-- Press 'normal' key.
--
-- @param   key         key to press
-- @return              true while press is active
--                      false if press finished
-----------------------------------------------------------------------------
local function keyDown(self,key)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.keyDown(key)
  end
  return true
end

-----------------------------------------------------------------------------
-- Release 'normal' key.
--
-- @param   key         key to release
-- @return              true while release is active
--                      false if release finished
-----------------------------------------------------------------------------
local function keyUp(self,key)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.keyUp(key)
  end
  return true
end


-----------------------------------------------------------------------------
-- Click 'functional' key.
--
-- @param   key         key to click
-- @param   time        time to hold key (in seconds)
-- @return              true while click is active
--                      false if click finished
-----------------------------------------------------------------------------
local function funcClick(self,key,time)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    if self.timeNext >= self.timeEnd + self.wait then
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
    self.timeNext = self.timeEnd + self.wait
    _GuiEvent.funcUp(key)
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + (self.demo and time or 0)
    self.timeNext = self.timeEnd
    _GuiEvent.funcDown(key)
  end
  return true
end

-----------------------------------------------------------------------------
-- Press 'functional' key.
--
-- @param   key         key to press
-- @return              true while press is active
--                      false if press finished
-----------------------------------------------------------------------------
local function funcDown(self,key)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.funcDown(key)
  end
  return true
end

-----------------------------------------------------------------------------
-- Release 'functional' key.
--
-- @param   key         key to release
-- @return              true while release is active
--                      false if release finished
-----------------------------------------------------------------------------
local function funcUp(self,key)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.funcUp(key)
  end
  return true
end

-----------------------------------------------------------------------------
-- Press 'alt' key.
--
-- @return              true while press is active
--                      false if press finished
-----------------------------------------------------------------------------
local function altDown(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.altDown()
  end
  return true
end

-----------------------------------------------------------------------------
-- Release 'alt' key.
--
-- @return              true while release is active
--                      false if release finished
-----------------------------------------------------------------------------
local function altUp(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.altUp()
  end
  return true
end

-----------------------------------------------------------------------------
-- Press 'ctrl' key.
--
-- @return              true while press is active
--                      false if press finished
-----------------------------------------------------------------------------
local function ctrlDown(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.ctrlDown()
  end
  return true
end

-----------------------------------------------------------------------------
-- Release 'ctrl' key.
--
-- @return              true while release is active
--                      false if release finished
-----------------------------------------------------------------------------
local function ctrlUp(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.ctrlUp()
  end
  return true
end

-----------------------------------------------------------------------------
-- Press 'shift' key.
--
-- @return              true while press is active
--                      false if press finished
-----------------------------------------------------------------------------
local function shiftDown(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.shiftDown()
  end
  return true
end

-----------------------------------------------------------------------------
-- Release 'shift' key.
--
-- @return              true while release is active
--                      false if release finished
-----------------------------------------------------------------------------
local function shiftUp(self)
  if self.timeEnd then
    if self.timeNext > os.clock() then return true end
    self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
    return false
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + self.wait
    self.timeNext = self.timeEnd
    _GuiEvent.shiftUp()
  end
  return true
end

-----------------------------------------------------------------------------
-- Wait specified time (seconds).
--
-- @param   time        time to wait
-- @return              true while waiting
--                      false if time finished
-----------------------------------------------------------------------------
local function timer(self,time)
  if self.timeEnd then
    if self.timeEnd > os.clock() then
      return true
    else
      self.timeBeg,self.timeEnd,self.timeNext = nil,nil,nil
      return false
    end
  else
    self.timeBeg = os.clock()
    self.timeEnd = self.timeBeg + (self.demo and time or 0)
    return true
  end
end

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
setmetatable(M,{__call = new})
M.altDown = altDown
M.altUp = altUp
M.ctrlDown = ctrlDown
M.ctrlUp = ctrlUp
M.funcClick = funcClick
M.funcDown = funcDown
M.funcUp = funcUp
M.goto = goto
M.gotoCenter = gotoCenter
M.keyClick = keyClick
M.keyDown = keyDown
M.keyUp = keyUp
M.keyString = keyString
M.leftClick = leftClick
M.leftClickDbl = leftClickDbl
M.leftDown = leftDown
M.leftUp = leftUp
M.shiftDown = shiftDown
M.shiftUp = shiftUp
M.timer = timer
return M

