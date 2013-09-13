local M = { help={}, test={}, _id="tester", _author="LD", _year=2013 }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  tester -- run modules and services tests

SYNOPSIS
  local test = require "mad.tester"
  test(mad.module)
  test(mad.module.submodule)

DESCRIPTION
  The tester module tests the modules and services and return statistics.

RETURN VALUES
  The module.

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------

local module = require "mad.module"

-- local -----------------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

-- metamethods -----------------------------------------------------------------

mt.__call = function (_, a)
  -- print("tester called with ", a, a and a._id or "unknown")

  if type(a) == "table" and a.test and a.test.self then
    return a.test.self()
  end

  if type(a) == "function" then
    local fn = module.registered_function[a]
    if fn then
      return fn.mod.test[fn.str]()
    end
  end

  return 0, 0
end

-- tests -----------------------------------------------------------------------

M.test.self = function (...)
  local help = require "mad.helper"
  local module = M
  help(module)
  help(module.foo)
  return 2, 2
end

-- end -------------------------------------------------------------------------
return module(M)
