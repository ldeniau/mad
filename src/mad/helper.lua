local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [[
NAME
  mad.helper -- display modules and services help on the console

SYNOPSIS
  local help = require "mad.helper"
  help(mad.module)
  help(mad.module.function)

DESCRIPTION
  The helper module displays the help of MAD modules and services on the
  terminal.

RETURN VALUES
  True if an help was found, false otherwise.

SEE ALSO
  mad.tester
]]

-- require ---------------------------------------------------------------------

local module = require "mad.module"

-- metamethods -----------------------------------------------------------------

local mt = {}; setmetatable(M, mt)

mt.__call = function (_, a)
  if type(a) == "table" then
    local mod_name, mod = module.get_module_name(a)
    if mod_name and mod.help.self then
      print(mod.help.self)
      return true
    end

  elseif type(a) == "function" then
    local fun_name, mod = module.get_function_name(a)
    if fun_name and mod.help[fun_name] then
      print(mod.help[fun_name])
      return true
    end

  else
    print("No help found for ", a)
    return false
  end
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
