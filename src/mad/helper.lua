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

--local module = require "mad.module"

-- metamethods -----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

mt.__call = function (_, a)
  -- print("helper called with ", a, a and a._id or "unknown")

  if type(a) == "table" then
    local mod_name, mod = module.get_module_name(a)
    if mod_name then print(mod.help.self) end
    return
  end

  if type(a) == "function" then
    local fun_name, mod = module.get_function_name(a)
    if fun_name then print(mod.help[fun_name]) end
    return
  end

  print("No help found for ", a)
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
