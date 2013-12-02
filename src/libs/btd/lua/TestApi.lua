-----------------------------------------------------------------------------
-- Supported test and miscelaneous methods.
--
-- Copyright (c) 2008, 2009 Wim Langers. All rights reserved.
-- Licensed under the same terms as Lua itself.
-- Based on LuaUnit.lua v1.3 under X11 License
-- see LICENSE.txt
--
-- @release 1.7.0 - 18 Apr 2009
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {CLASS = 'btd.lua.TestApi'}
local MT = {__index = M,__metatable = {}}

-- Some people like assertEquals(actual,expected) and some people prefer
-- assertEquals(expected,actual).
M.USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS = true

-----------------------------------------------------------------------------
-- Assert that calling f with the arguments will raise an error
-- @param   f       function under test
-- @param   ...     parameters to function onder test
-- @usage           fails(f,1,2) => f(1,2) should generate an error
-----------------------------------------------------------------------------
local function fails(f,...)
  if not pcall(f,...) then return end
  error("No error generated",2)
end

-----------------------------------------------------------------------------
-- Assert that calling f with the arguments will not raise an error
-- @param   f       function under test
-- @param   ...     parameters to function onder test
-- @usage           succeeds(f,1,2) => f(1,2) should not generate an error
-----------------------------------------------------------------------------
local function succeeds(f,...)
  if pcall(f,...) then return end
  error("Error generated",2)
end

-----------------------------------------------------------------------------
-- Assert that two values are equal and calls error else
-- @param   actual      result of test
-- @param   expected    expected result of test
-- @usage               equals(1 + 1,2) => 1 + 1 = 2 ?
-----------------------------------------------------------------------------
local function equals(actual,expected)
  if not M.USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS then expected,actual = actual,expected end
  local nesting = ''
  local function equalsRec(actual,expected,key)
    local errorMsg = ''
    if type(actual) == 'table' and type(expected) == 'table' then
      for k,v in pairs(expected) do
        if actual[k] == nil then
          errorMsg = errorMsg..nesting..'expected : key : '..tostring(k)..'\n'
          errorMsg = errorMsg..nesting..'actual   : key : '..tostring(k)..' missing\n'
        else
          errorMsg = errorMsg..equalsRec(actual[k],v,k)
        end
      end
      for k,v in pairs(actual) do
        if expected[k] == nil then
          errorMsg = errorMsg..nesting..'expected : key : not expected\n'
          errorMsg = errorMsg..nesting..'actual   : key : '..tostring(k)..'\n'
        end
      end
    elseif type(actual) ~= type(expected) then
      errorMsg = errorMsg..nesting..'expected : '..type(expected)..', actual '..type(actual)..'\n'
    elseif actual ~= expected then
        errorMsg = errorMsg..nesting..'expected : '..(key and 'table key '..key..' = ' or '')..(type(expected) == 'string' and "\n'"..expected.."'\n" or tostring(expected)..', ')
        errorMsg = errorMsg..nesting..'actual   : '..(key and 'table key '..key..' = ' or '')..(type(actual) == 'string' and "\n'"..actual.."'" or tostring(actual))..'\n'
    end
    return errorMsg
  end
  local errorMsg = equalsRec(actual,expected)
  if #errorMsg == 0 then return end
  error(errorMsg,2)
end

-----------------------------------------------------------------------------
-- Assert that two values are different and calls error else
-- @param   actual      result of test
-- @param   expected    expected result of test
-- @usage               differs(1 / 0,1) => 1 / 0 ~= 1 ?
-----------------------------------------------------------------------------
local function differs(actual,expected)
  if not M.USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS then expected,actual = actual,expected end
  local function differsRec(actual,expected,key)
    if type(actual) == 'table' and type(expected) == 'table' then
      for k,v in pairs(expected) do
        if actual[k] == nil or differsRec(actual[k],v,k) then return true end
      end
      for k,v in pairs(actual) do
        if expected[k] == nil then return true end
      end
    elseif type(actual) == 'table' or type(expected) == 'table' or actual ~= expected then
      return true
    end
    return false
  end
  if differsRec(actual,expected) then return end
  error('expected == actual',2)
end

-----------------------------------------------------------------------------
-- Wrap a set of functions into a Runnable test class:
-- @param   ...     names of functions to be processed
-- @return          list of test methods
-- @usage           TestFunctions = wrapFunctions(f1,f2,f3,f3,f5)
--                  Now,TestFunctions will be picked up by LuaUnit:run()
-----------------------------------------------------------------------------
local function wrap(...)
  local testClass = {}
  for _,testMethod in ipairs{...} do testClass[testMethod] = _G[testMethod] end
  return testClass
end

-----------------------------------------------------------------------------
-- Get path to test class.
-- Only works/makes sense when called as 'require' from a test class.
-----------------------------------------------------------------------------
local trace = string.match(debug.traceback(),"'require'.-(%w.-):%d-:")..':1:'

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
M.differs = differs
M.equals = equals
M.fails = fails
M.succeeds = succeeds
M.trace = trace
M.wrap = wrap
assertEquals = equals -- to be deprecated ?
assert_Equals = equals -- to be deprecated ?
assertError = fails -- to be deprecated ?
assert_error = fails -- to be deprecated ?
wrapFunctions = wrap -- to be deprecated ?
return M
