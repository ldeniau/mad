local tpsa, factory = require "lib.tpsa", require "factory"

io.stderr:write([[Usage: luajit make_mul_input.lua nv no [output_file]
  output_file defaults to ./tpsa.out
]])

tpsa.set_package("ffi")

local nv, no = tonumber(arg[1]), tonumber(arg[2])

local t = tpsa.init(nv,no)
t:rand(1.1, 5.5, os.time())

local filename = arg[3] or "tpsa.out"
local file = io.open(filename,"w")
t:print(file)
t:print(file)

io.stderr:write(string.format("Done! Written '%s' for nv=%d no=%d\n", filename, nv, no))

