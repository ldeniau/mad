local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [=[
NAME
  mad.module -- register MAD modules and functions

SYNOPSIS
  module = require"mad.module"
  mod_name           = module.get_module_name(mod)
  fun_name, mod_name = module.get_function_name(fun)
  mod_list, fun_list = module.get_all()

DESCRIPTION
  The module mad.module register MAD modules and functions for name lookup. MAD
  modules must have 'help' and 'test' tables.

  A MAD module should typically start by:

    local M = { help={}, test={} }
    M.help.self = [[
      module documentation
    ]]

  The module name is stored into the property _id of the table.

RETURN VALUES
  The interface to the MAD modules database.

ERRORS
  If the module does not contain a 'help' and 'test' tables, an invalid argument
  error is raised.

SEE ALSO
  mad.helper, mad.tester, mad.object
]=]

-- data ------------------------------------------------------------------------

local registered = false
local registered_module = {}    -- { [mod] = 'mod_name' }
local registered_function = {}  -- { [fun] = { fun_name = 'fun_name', mod_name = 'mod_name' } }

-- local -----------------------------------------------------------------------

local register_function = function (mod, mod_name)
  for fun_name,fun in pairs(mod) do
    if type(fun) == "function" then
      registered_function[fun] = { fun_name = fun_name, mod_name = mod_name }
    end
  end
end

local register_module = function (mod_name)
  local mod = package.loaded[mod_name]

  if registered_module[mod] ~= nil then return end

  if not mod.help then
    error(("module '%s' has NO help"):format(mod_name))
  end
  if not mod.test then
    error(("module '%s' has NO test"):format(mod_name))
  end

  register_function(mod, mod_name)
  registered_module[mod] = mod_name
end

local register_mad_modules = function ()
  local mad = require "mad"

  for mod_name,mod in pairs(package.loaded) do
    if type(mod) == "table" and mod_name:sub(1,4) == "mad." and not mod_name:find("%.test%.") then
      register_module(mod_name)
    end
  end

  registered = true
end

-- methods -----------------------------------------------------------------

M.reset = function ()
  registered = false
  registered_module = {}
  registered_function = {}
end

M.get_all = function ()
  if not registered then
    register_mad_modules()
  end

  return registered_module, registered_function
end

M.get_module_name = function (mod)
  if not registered then
    register_mad_modules()
  end

  return registered_module[mod]
end

M.get_function_name = function (fun)
  if not registered then
    register_mad_modules()
  end
    
  local info = registered_function[fun]
  if info then
    return info.fun_name, info.mod_name
  else
    return nil, nil
  end
end

-- tests -----------------------------------------------------------------------

-- TODO
M.foo = function () print("module.foo called") end
M.help.foo = "This is the help of module.foo for testing purpose"
M.test.foo = function () print("This is the test of module.foo") end

M.test.self = function ()
  local help = require "mad.helper"
  local module = M
  help(module)
  help(module.foo)
  return 2, 2
end

-- end -------------------------------------------------------------------------
return M