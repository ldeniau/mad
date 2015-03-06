local tpsa, factory = require "lib.tpsa", require "factory"
local usage = " luajit ../examples/tpsa/tpsa-ex-io.lua nv no (ffi | berz) (in | out) "

local nv, no = tonumber(arg[1]), tonumber(arg[2])
tpsa.set_package(arg[3])

factory.setup(tpsa,nv,no)

if     arg[4] == "out" then
  local t = factory.full()
  t:print()
elseif arg[4] == "in"  then
  local t = factory.new_instance()
  t:read()
  t:print()
else
  error(usage)
end


