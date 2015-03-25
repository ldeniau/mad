local factory, check = require"factory", require "check"
local clock, printf = os.clock, factory.printf

local header_fmt = "nv\tno\tnl       \t"
local line_fmt   = "%d\t%d\t%8d\t"
local trials = arg[4] or 5

local function timeit(fun, nl, p1, p2, p3, p4, p5, p6, p7)
  local start = clock()
  for l=1,nl do fun(p1, p2, p3, p4, p5, p6) end
  return clock() - start
end

-- benchmark the speed of fct_name from module mod_name using parameters from filename
local function bench(mod_name, fct_name, filename)
  local NV, NO, NL = factory.read_params(filename)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)
  for t=1,trials do printf("t_%d\t", t) end
  printf("avg\tmin\tmax\n")

  local tpsa = require(mod_name)

  local Ts = {}  -- times
  for i=1,#NL do
--    check.do_all_checks(tpsa, NV[i], NO[i])

    factory.setup(tpsa, NV[i], NO[i])
    printf(line_fmt, NV[i], NO[i], NL[i])

    Ts[i] = {}
    local min, max, sum = 1000, 0, 0
    for t=1,trials do
      Ts[i][t] = timeit(tpsa[fct_name], NL[i], factory.get_args(fct_name))
      min = Ts[i][t] < min and Ts[i][t] or min
      max = Ts[i][t] > max and Ts[i][t] or max
      sum = sum + Ts[i][t]
      printf("%.3f\t", Ts[i][t])
    end
    printf("%.3f\t%.3f\t%.3f\n", sum/trials, min, max)
  end
end

local usage = [[
Usage: luajit benchmark.lua [-h] module_name operator [params-file] [trials]
]]

local help = [[
  mod_name: lib.tpsaFFI | lib.tpsaBerz | lib.tpsaYang | lib.tpsaMC
  operator: mul | add | sub
Example: luajit benchmark.lua lib.tpsaFFI mul bench-params/mul-params.txt
]]

printf(usage)

if arg[1] == "-h" then
  printf(help)
  os.exit()
end

bench(arg[1], arg[2], arg[3])


