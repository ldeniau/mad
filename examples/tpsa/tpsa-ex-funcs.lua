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

b = a:der(2)
b:print()

local s, c, sc_s, sc_c = new(), new(), new(), new()
tpsa.sin(a,s)
tpsa.cos(a,c)

tpsa.sincos(a,sc_s,sc_c)

local check = require"check"
check.identical(s,sc_s,1e-20, factory.To, "sin", "absolute")
check.identical(c,sc_c,1e-20, factory.To, "cos", "absolute")

tpsa.sinh(a,s)
tpsa.cosh(a,c)

tpsa.sincosh(a,sc_s,sc_c)

check.identical(s,sc_s,1e-20, factory.To, "sin", "absolute")
check.identical(c,sc_c,1e-20, factory.To, "cos", "absolute")


