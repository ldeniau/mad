local tpsa, factory = require "lib.tpsa", require "factory"

--[=[
t:get{}           -- equiv to t:get_at(t:get_idx{}))
t:set({},v)
t:get_sp{}        -- equiv to t:get{} but with sparse mono
t:set_sp{}        -- equiv to t:set{} but with sparse mono
t:get_idx{}
t:get_at(idx)
t:set_at(idx, v)

-- interface for benchmarking
-- mono_t -> library specific ctype (e.g. ord_t[], int[])
-- use factory.get_args("getm") (or "setm")
t:getm(mono_t)
t:setm(mono_t,v)
]=]

local package = arg[1] or 'ffi'
local nv, no = arg[2] or 3, arg[3] or 2
tpsa.set_package(package)
local t = tpsa.init(nv,no)

-- poke
t:set({1,0,0}, -3.5)
t:set({0,2,0}, -2.0)
t:set({1,1}  , -4.0)    -- filled with 0s
--t:set({0,0,3}, -1.0)  -- invalid mono behaviour? ffi: fail | yang: ignore | berz: goes to cst term
t:print()

-- peek
print(t:get({1,0}))
--print(t:get({0,3}))     -- invalid mono behaviour? ffi: fail | yang and berz: return 0

-- GTPSA-only features
if package == "ffi" then
  -- if using the same mono many times, one could cache its index and reuse it
  local idx = t:get_idx({1,0,0})
  for i=1,5 do
    local v = t:get_at(idx)
    t:set_at(idx,2*v)
    -- some other calculation
  end

  -- GTPSA supports sparse representation of mono; useful when having many knobs
  t = tpsa.init({2,2,2,2,1,1}, 2, {1,1,1,1,1}, 1)
  -- mono is array of (idx,ord)
  t:set_sp({5,1, 6,1, 10,1}, 3.5) -- equiv to t:set({0,0,0,0,1,1, 0,0,0,1,0}, 3.5)
  local v = t:get_sp({2,2, 8,1})  -- equiv to t:get({0,2,0,0,0,0, 0,1,0,0,0})
end


-- ADVANCED ----------------
-- to bypass the table -> mono conversion, use getm/setm
-- see tpsa-ex-factory.lua for factory usage
factory.setup(tpsa,nv,no)
local cdata_To, dummy_val, nnv = factory.get_args("setm")

-- setup all order 2
t = factory.new_instance()
for i=cdata_To.ps[2],cdata_To.pe[2] do
  t:setm(cdata_To[i], dummy_val, nnv)
end
t:print()


