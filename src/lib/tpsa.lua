local ffi = require"ffi"

local packages = {
  mad  = "tpsaFFI",
  berz = "tpsaBerz",
  yang = "tpsaYang"
}


local M = {}
local MT = { __index = M }

local tpsa
local curr_loaded = {}

local folder_of_this_file = (...):match("(.-)[^%.]+$")
function M.set_package(name)
  if not packages[name] then
    error("Unrecognized package title: " .. name .. ". Use one of: mad, yang, berz")
  end
  tpsa = require(folder_of_this_file .. packages[name])
  curr_loaded =  { name=name }
  setmetatable(M, getmetatable(tpsa))
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
  else
    curr_loaded.t = tpsa.init(nv,no)
  end
  return curr_loaded.t
end

function M.new()
  return curr_loaded.t:same()
end


return M
