local tpsa, factory = require "lib.tpsa", require "factory"

local nv,no = 3,3
tpsa.set_package("ffi")
factory.setup(tpsa,nv,no)

local new = factory.new_instance
local a, b = factory.full(), new()

tpsa.inv(a,b) -- 1/a
tpsa.sqrt(a,b)
tpsa.exp(a,b)
b:print()

local c = a:der(2)
c:print()