local M = { help={}, test={} }

-- module ----------------------------------------------------------------------

M.help.self = [=[
NAME
  mad.module -- initialize MAD modules properly

SYNOPSIS
  local module = require "mad.module"
  local fun_name, mod_name = module.get_function_name(fun)
  local mod_name = module.get_module_name(module)

DESCRIPTION
  This module sets MAD modules up within the MAD environment. MAD modules must
  have tables for help and test. A typical MAD module starts by
    local M = { help={}, test={} }
    M.help.self = [[
      module documentation
    ]]

RETURN VALUES
  The interface to the MAD modules and services database.

SEE ALSO
  mad.helper, mad.tester, mad.object
]=]

-- data ------------------------------------------------------------------------

local registered = false
local registered_module = {}
local registered_function = {}

-- local -----------------------------------------------------------------------

local register_mad_function = function (mod, mod_name)
  for fun_name,fun in pairs(mod) do
    if type(fun) == "function" then
      registered_function[fun] = { fun_name = fun_name, mod_name = mod_name }
    end
  end
end

local register_mad_module = function (mod_name)
  local mod = package.loaded[mod_name]

  if not registered_module[mod] then
    if not mod.help then
      error(("MAD module '%s' has NO help"):format(mod_name))
    end
    if not mod.test then
      error(("MAD module '%s' has NO test"):format(mod_name))
    end

    register_mad_function(mod, mod_name)
    registered_module[mod] = mod_name
  end
end

local register_mad_modules = function ()
  for mod_name,mod in pairs(package.loaded) do
    if type(mod) == "table" and mod_name:sub(1,4) == "mad." then
      register_mad_module(mod_name)
    end
  end

  register_mad_module("mad")
  M.registered = true
end

-- methods -----------------------------------------------------------------

M.reset = function ()
  registered = false
  registered_module = {}
  registered_function = {}
end

M.list = function (list_fun)
  if not registered then
    register_mad_modules()
  end

  for _,v in pairs(registered_module) do
    print(("module '%s'"):format(v))
  end

  if list_fun then
    for _,v in pairs(registered_function) do
      print(("function '%s.%s'"):format(v.mod_name, v.fun_name))
    end
  end
end

M.get_module_name = function (mod)
  if not registered then
    register_mad_modules()
  end

  return registered_module[mod], mod
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
