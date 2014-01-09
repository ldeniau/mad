local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.tester -- run modules and services tests

SYNOPSIS
  local test = require "mad.tester"
  test(mad.module)
  test(mad.module.submodule)

DESCRIPTION
  The tester runs the test of MAD modules and services and return statistics.

RETURN VALUES
  The number of the tests failed and passed

SEE ALSO
  mad.helper
]]

-- require ---------------------------------------------------------------------

local module = require "mad.module"

-- metamethods -----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

mt.__call = function (_, a)
  if module.get_module_name(a) and a.test.self then
    return a.test.self()
  end

  local fun_name, mod = module.get_function_name(a)

  if fun_name and mod.test[fun_name] then
    return mod.test[fun_name]()
  end

  return 0, 0
end

-- tests -----------------------------------------------------------------------

M.test.self = function ()
  local help = require "mad.helper"
  local module = M
  help(module)
  help(module.foo)
  return 2, 2
end

-- end -------------------------------------------------------------------------
return M
