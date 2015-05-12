local ffi, check, factory = require"ffi", require"check", require"factory"
local clock = require"lib.omp".omp_get_wtime
local insp, printf = require"utils.inspect", factory.printf
local tpsa = require"lib.tpsaFFI"
local berz = require"lib.tpsaBerz-dbg"
local map = require"lib.map"


local ma = map.make_map{v={'x','px','y','py'}, x={2,2,0,0}, dx=1, k={1,1}, dk=2}
local mb = map.make_map{v={'x','px','y','py'}, x={2,2,0,0}, dx=1, k={1,1}, dk=2}
ma.x:set_sp({1,1, 3,1}, 3.5)
ma.x:set_sp({2,1, 3,1}, 4.5)
ma.x:set_sp({4,1, 3,1}, 5.5)

ma.x:print()

os.exit()

