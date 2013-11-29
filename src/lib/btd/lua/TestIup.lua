-----------------------------------------------------------------------------
-- Supported IUP test and miscelaneous methods.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
--
-- @release 1.7.0 - 18 Apr 2009
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.TestIup'}
local MT = {__index = M,__metatable = {}}
_G.iup = nil
package.loaded.iup = nil -- cross wire Iup
package.loaded.iuplua = nil
package.loaded.iupluacontrols = nil
require('iuplua')
require('iupluacontrols')
M.iupMainLoop = iup.MainLoop -- catch gui testing (if any)
iup.MainLoop = function() M.gui = true end
M.iupSetIdle = iup.SetIdle
iup.SetIdle = function (idle) M.idle = idle end -- catch idle method (if any)

-----------------------------------------------------------------------------
-- Run Iup main loop.
-- If a function is passed, it is called on every idle time processing, then
-- the normal idle time processing (if present) is called. The function is
-- responsible for terminating the main loop by calling 'iup.ExitLoop' or by
-- returning 'IUP_CLOSE'.
-- If no function is passed, then main loop is immediately terminated at the
-- first idle time processing.
-- @param   func    idle (test) function
-- @usage           iupLoop(function)
--                  Now, test function will be run in idle time of main loop
-----------------------------------------------------------------------------
local function iupLoop(func)
  assert(M.gui,'No iup.MainLoop() function defined in class !')
  if type(func) == 'function' then
    M.iupSetIdle(
    function()
      if M.idle then M.idle() end
      return func()
    end)
  else
    M.iupSetIdle(
    function()
      iup.ExitLoop()
    end)
  end
  M.iupMainLoop()
end

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
M.iupLoop = iupLoop
return M
