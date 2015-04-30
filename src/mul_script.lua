local tpsa, factory = require "lib.tpsa", require "factory"

tpsa.set_package(arg[4] or "ffi")
local nv, no = tonumber(arg[1]), tonumber(arg[2])
factory.setup(tpsa,nv,no)
local a, b = factory.full(), factory.full()
local r = a * b
r:print()
