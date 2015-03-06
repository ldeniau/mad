local tpsa, factory = require "lib.tpsa", require "factory"

local nv,no = 2,3
tpsa.set_package("ffi")
tpsa.init(nv,no)

local ma = tpsa.get_map()
local mi = tpsa.get_map()
local mb = tpsa.get_map()
local mc = tpsa.get_map()

ma[1]:set({1,0}, 3.0)
ma[1]:set({0,1}, 4.0)
ma[1]:set({1,1},-1.0)
ma[1]:set({1,2}, 2.5)

ma[2]:set({1,0},-1.0)
ma[2]:set({0,1},-5.0)

-- ... --- ... --- ...

mb[1]:set({1,0}, 3.0)
mb[2]:set({0,1}, 4.0)

tpsa.minv(ma,mi)
tpsa.compose(ma,mb,mc)
factory.setup(tpsa,nv,no)
factory.print_all(io.output(), mc)
