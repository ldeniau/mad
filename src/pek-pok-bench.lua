local factory, check = require"factory", require"check"
local clock, printf = os.clock, factory.printf
local header_fmt = "nv\tno\tnc\tnl\ttime(s)\n"
local line_fmt   = "%d\t%d\t%d\t%d\t%f\n"

local function timeit(fun, nl, t, ...)
  local To, p1, p2 = ...
  local start = clock()
  for l=1,nl do
    for i=0,#To do
      fun(t, To[i], p1, p2)
    end
  end
  return clock() - start
end

local function bench(mod_name, fct_name, filename)
  local NV, NO, NL = factory.read_params(filename)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)

  local tpsa = require(mod_name)

  local Ts = {}  -- times
  for i=1,#NL do
    check.do_all_checks(tpsa, NV[i], NO[i])

    factory.setup(tpsa, NV[i], NO[i])
    local t = factory.new_instance()
    Ts[i] = timeit(tpsa[fct_name], NL[i], t, factory.get_args(fct_name))

    printf(line_fmt, NV[i], NO[i], #factory.To+1, NL[i], Ts[i])
  end
end

local usage = [[
Usage:   luajit pek-pok-bench.lua -h mod_name fct_name [params_filename]
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

bench(arg[1], arg[2], arg[3])


