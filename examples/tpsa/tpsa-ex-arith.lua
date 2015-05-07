local tpsa, factory = require "lib.tpsa", require "factory"

local nv,no = 3,3
tpsa.set_package("ffi")
tpsa.init(nv,no)
local a, b = tpsa.new(), tpsa.new()
a:set({1,0,0}, 1.0)
a:set({0,2,1}, 3.0)
a:set({1,0,1}, 4.0)

b:set({0,2,0}, 2.0)
b:set({1,1,1},-3.0)
b:set({0,1,1}, 5.0)


local c = 1 + a - b + 2
c = 2 * a + b * 3 + a * b
c:print()
c = c:new(2)
c.cpy(2 * a + b * 3 + a * b, c) -- truncate result
c:print()


c = a / (b+1)

a:print()
b:print()
c:print()