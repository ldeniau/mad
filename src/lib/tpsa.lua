local ffi = require"ffi"

local packages = {
  mad  = "tpsaFFI",
  berz = "tpsaPTC",
  yang = "tpsaYang"
}


local M = {}

local tpsa
local curr_loaded = {}

local folder_of_this_file = (...):match("(.-)[^%.]+$")
function M.set_package(name)
  if not packages[name] then
    error("Unrecognized package title: " .. name .. ". Use one of: mad, yang, berz")
  end
  tpsa = require(folder_of_this_file .. packages[name])
  curr_loaded =  { name=name }
  setmetatable(M, { __index = tpsa })
end

function M.init(nv,no,var_ords,knb_ords,mvo,mko)
  if not curr_loaded.name then
    error("Set a package first")
  elseif curr_loaded.name == "mad" then
    if not var_ords then
      var_ords = {}
      for i=1,nv do var_ords[i] = no end
    end
    curr_loaded.t = tpsa.init(var_ords, no, knb_ords, mvo, mko)
    curr_loaded.var_ords = var_ords
  else
    curr_loaded.t = tpsa.init(nv,no)
  end
  curr_loaded.nv = nv
  return curr_loaded.t
end

function M.new()
  return curr_loaded.t:same()
end

function M.get_map()
  local map = {}
  if curr_loaded.name == "mad" then
    for i=1,curr_loaded.nv do
      map[i] = curr_loaded.t:new(curr_loaded.var_ords[i])
    end
  else
    for i=1,curr_loaded.nv do
      map[i] = curr_loaded.t:new()
    end
  end
  return map
end


return M
