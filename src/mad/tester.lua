local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.tester -- run modules and functions tests

SYNOPSIS
  test = require"mad.tester"
  test(mad.module)
  test(mad.module.function)

DESCRIPTION
  The tester module runs the test of registered MAD modules and functions and
  return the statistics.

RETURN VALUES
  The number of the tests failed and passed

SEE ALSO
  mad.helper, mad.module
]]

-- requires --------------------------------------------------------------------

local module = require"mad.module"

-- metamethods -----------------------------------------------------------------

local MT = {}; setmetatable(M, MT)

function MT:__call(a)
  if module.get_module_name(a) and a.test.self then
    return a.test.self()
  end

  local fun_name, mod = module.get_function_name(a)

  if fun_name and mod.test[fun_name] then
    return mod.test[fun_name]()
  end

  return 0, 0 -- ??
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
