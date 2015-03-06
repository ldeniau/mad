local tpsa, factory = require "lib.tpsa", require "factory"
local usage = " luajit ../examples/tpsa/tpsa-ex-io.lua nv no (ffi | berz) (in | out)\n"
io.stderr:write(usage)

--[[
  this example can be used to verify that I/O of FFI and Berz are compatible
  I/O redirection is needed as Fortran streams cannot be interfaced from Lua (in an easy way)
  Example:
  $ luajit ../examples/tpsa/tpsa-ex-io.lua 3 3 ffi  out > tpsa.out
  $ luajit ../examples/tpsa/tpsa-ex-io.lua 3 3 ffi  in  < tpsa.out # should see same content as tpsa.out
  $ luajit ../examples/tpsa/tpsa-ex-io.lua 3 3 berz in  < tpsa.out # should see same coeff   as tpsa.out

  $ luajit ../examples/tpsa/tpsa-ex-io.lua 3 3 berz out > berz.out
  $ luajit ../examples/tpsa/tpsa-ex-io.lua 3 3 berz in  < berz.out # should see same content as berz.out
  $ luajit ../examples/tpsa/tpsa-ex-io.lua 3 3 ffi  in  < berz.out # should see same coeff   as berz.out

]]
local nv, no = tonumber(arg[1]) or 3, tonumber(arg[2]) or 3
local package = arg[3] or "ffi"
tpsa.set_package(package)

factory.setup(tpsa,nv,no)

if     arg[4] == "out" then
  local t = factory.full()
  t:print()
elseif arg[4] == "in"  then
  local t = factory.new_instance()
  t:read()
  t:print()
end

-- I/O with files
if package == "ffi" and unused then
--if package == "ffi" then
  local file = io.open("tpsa.out","w")
  local t = tpsa.init({2,3,3},4,{1,1},2)
  t:rand(-2.0,2.0, os.time())
  t:print(file)
  file:close()

  file = io.open("tpsa.out", "r")
  local new_t = t:new(2)   -- new_t has hard truncation order 2
  new_t:read(file)
  new_t:print()            -- should see orders 0,1,2
end


