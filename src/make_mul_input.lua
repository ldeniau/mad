local tpsa, factory = require "lib.tpsa", require "factory"

io.stderr:write([[Usage: luajit make_mul_input.lua nv no (in | out) [file]
  out produces   file tpsa.in, to be read by other program
  in  reads from file tpsa.out, multiplies and puts result into res.out

]])

tpsa.set_package("ffi")

local nv, no = tonumber(arg[1]), tonumber(arg[2])

if arg[3] == "out" then
  local file = io.open(arg[4] or "tpsa.in", "w")
  factory.setup(tpsa,nv,no)
  local t = factory.full()
  t:print(file)
  t:print(file)
  io.stderr:write("Written to ", arg[4] or "tpsa.in", "\n")
elseif arg[3] == "in" then
  local file = io.open(arg[4] or "tpsa.in", "r")
  local a = tpsa.read(file)
  local b = tpsa.read(file)
  local r = a * b
  r:print(io.open("res.out", "w"))
  io.stderr:write("Read from ", arg[4] or "tpsa.in", " Written to res.out\n")
end


