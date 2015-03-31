local tpsa, factory = require "lib.tpsa", require "factory"

io.stderr:write([[Usage: luajit make_mul_input.lua nv no [output_file]
  output_file defaults to ./tpsa.out
]])

tpsa.set_package("ffi")

local nv, no = tonumber(arg[1]), tonumber(arg[2])

local t = tpsa.init(nv,no)
for i=0,nv do
  t:set_at(i,1.2)
end

local a = t:cpy()
for o=1,no do
  a = a * t
end

local file = io.open(arg[3] or "tpsa.out","w")
a:print(file)
a:print(file)
