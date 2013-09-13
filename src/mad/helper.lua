local M = { _id="helper", _author="LD", _year=2013, help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  helper -- display modules and services help on the console

SYNOPSIS
  local help = require "mad.helper"
  help(mad.module)
  help(mad.module.function)

DESCRIPTION
  The helper module displays the help of modules and services on the console.

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
  -- print("helper called with ", a, a and a._id or "unknown")

  if type(a) == "table" and a.help and a.help.self then
    print(a.help.self)
    return
  end

  if type(a) == "function" then
    local fn = module.registered_function[a]
    if fn then
      print(fn.mod.help[fn.str])
      return
    end
  end

  print("No help found")
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
