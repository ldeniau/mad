local factory = require"factory"
local tpsa = require "lib.tpsaFFI"
local berz = require "lib.tpsaBerz"
local clock = os.clock

local NK,NO,NL = factory.read_params("bench-params/knb-params.txt")

for i=1,#NK do
--    local a = tpsa.init(6,2,NK[i],1)
    local a = tpsa.init(6+NK[i],2)
    a:rand(1.1,3.3,os.time())
    local b = a:cpy()
    local c = a:same()

    local t0 = clock()
    for i = 1,NL[i] do
        tpsa.mul(a,b,c)
    end
    local t1 = clock()

    print(NK[i], NO[i], NL[i], t1-t0)
end
