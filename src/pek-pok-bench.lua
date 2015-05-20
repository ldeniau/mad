local factory, check = require"factory", require"check"
local clock, printf = os.clock, factory.printf
local header_fmt = "nv\tno\tnc\t      nl\t"
local line_fmt   = "%d\t%2d\t%d\t%8d\t"

-- INPLACE shuffling; assumes list[0] exists
local function shuffle(list)
  math.randomseed(os.time())
  local rand = math.random
  local l = #list
  for i=0,l do
    local idx1, idx2 = rand(l+1) - 1, rand(l+1) - 1
    list[idx1], list[idx2] = list[idx2], list[idx1]
  end
end

local function timeit(fun, nl, t, To, p1, p2)
  local start = clock()
  for l=1,nl do
    for i=0,#To do
      fun(t, To[i], p1, p2)
    end
  end
  return clock() - start
end

local function bench(mod_name, fct_name, filename, trials)
  local NV, NO, NL = factory.read_params(filename)
  trials = trials or 5

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)
  for t=1,trials do printf("t_%d\t", t) end
  printf("avg\tmin\tmax\n")

  local tpsa = require(mod_name)

  local Ts = {}  -- times
  for i=1,#NL do
    check.do_all_checks(tpsa, NV[i], NO[i])

    factory.setup(tpsa, NV[i], NO[i])
    printf(line_fmt, NV[i], NO[i], #factory.To+1, NL[i])

    Ts[i] = {}
    local min, max, sum = 1000, 0, 0
    for j=1,trials do
      local To, t, l, v = factory.get_args(fct_name)
      shuffle(To)
      Ts[i][j] = timeit(tpsa[fct_name], NL[i], t, To, l, v)

      min = Ts[i][j] < min and Ts[i][j] or min
      max = Ts[i][j] > max and Ts[i][j] or max
      sum = sum + Ts[i][j]
      printf("%.3f\t", Ts[i][j])
    end
    printf("%.3f\t%.3f\t%.3f\n", sum/trials, min, max)
  end
end

local usage = [[
Usage:   luajit pek-pok-bench.lua [-h] mod_name fct_name [params_filename]
]]
local help = [[
  mod_name: lib.tpsaFFI | lib.tpsaBerz | lib.tpsaYang | lib.tpsaMC
  fct_name: setm | getm
Example: luajit pek-pok-bench.lua lib.tpsaFFI setm     bench-params/pek-params.txt
  Note: `fct_name` is called for each of the coefficients, in every loop
]]

printf(usage)
if arg[1] == "-h" then
  printf(help)
  os.exit()
end

bench(arg[1], arg[2], arg[3], arg[4])


