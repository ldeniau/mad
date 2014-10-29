local factory, check = require"factory", require"check"
local clock = os.clock
local header_fmt = "nv\tno\tnc\tnl\ttime(s)\n"
local line_fmt   = "%d\t%d\t%d\t%d\t%f\n"

local function printf(s, ...)
  io.write(s:format(...))
end

local function timeit(fun, nl, fct_name)
  local t, To, p1, p2 = factory.get_params(fct_name)
  local start = clock()
  for l=1,nl do
    for i=0,#To do
      fun(t, To[i], p1, p2)
    end
  end
  return clock() - start
end

local function bench(mod_name, fct_name, filename)
  printf("Usage:   luajit pek-pok-bench.lua mod_name    fct_name [params_filename]\n")
  printf("  mod_name: lib.tpsaFFI | lib.tpsaBerz | lib.tpsaYang | lib.tpsaMC\n")
  printf("  fct_name: setm | getm\n")
  printf("Example: luajit pek-pok-bench.lua lib.tpsaFFI setm     bench-params/pek-params.txt\n")
  printf("  Note: `fct_name` is called for each of the coefficients, in every loop\n")
  printf("------------------------------------------------------------------------\n")

  if not filename then filename = fct_name .. "-params.txt" end
  local NV, NO, NL = factory.read_params(filename)
  assert(#NV == #NO and #NV == #NL)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)

  local tpsa = require(mod_name)

  local Ts = {}  -- times
  for i=1,#NL do
    check.do_all_checks(tpsa, NV[i], NO[i])

    factory.setup{tpsa, NV[i], NO[i]}
    Ts[i] = timeit(tpsa[fct_name], NL[i], fct_name)

    printf(line_fmt, NV[i], NO[i], #factory.To+1, NL[i], Ts[i])
  end
end


bench(arg[1], arg[2], arg[3])


