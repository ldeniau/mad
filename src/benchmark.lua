local clock = os.clock
local factory, check = require"factory", require "check"
local fill_ord1, fill_full = check.fill_ord1, check.fill_full

local header_fmt, line_fmt

local function printf(s, ...)
  io.write(s:format(...))
end

local function timeit(fun, nl, t1, t2, r)
  local start = clock()
  for l=1,nl do fun(t1, t2, r) end
  return clock() - start
end

local function setup(tpsa, nv, no)
  local vars = {}
  for i=1,nv do vars[i] = no end

  local t = tpsa.init(vars, no) -- call tpsa constructor, i.e. the module
  fill_ord1(t, nv)
  fill_full(t, no)

  check.setup(tpsa, vars, no)

  return t, t:cpy(), t:new()
end

-- benchmark the speed of fct_name from module mod_name using parameters from filename
local function bench(mod_name, fct_name, filename, print_size)
  printf("Usage: luajit benchmark.lua mod_name fct_name [filename] [print_size?]\n")

  if not filename then filename = fct_name .. "-params.txt" end
  local NV, NO, NL = check.read_params(filename)
  assert(#NV == #NO and #NV == #NL)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)

  local tpsa = require(mod_name)

  local Ts = {}
  for i=1,#NL do
    local t1, t2, r = factory.setup(tpsa, fct_name, NV[i], NO[i])
    check.print_all(t1, t2, r)

    Ts[i] = timeit(tpsa[fct_name], NL[i], t1, t2, r)

    check.print_all(t1, t2, r)
    check.with_berz(1e-6)
    if print_size then
      local ops = tpsa[fct_name](t1, t2, r)
      local nc, tsize, dsize = r._T.D.nc, r.size, r._T.D.size
      tsize, dsize = tsize / 1024, dsize / 1024
      printf(line_fmt, NV[i], NO[i], NL[i], nc, ops, tsize, dsize, Ts[i])
    else
      printf(line_fmt, NV[i], NO[i], NL[i], Ts[i])
    end
  end

  check.tear_down()
end

if arg[4] then
  header_fmt = "nv\tno\tnl      \t  nc\top_in_mul\ttpsa_sz(Kb)\tdesc_sz(Kb)\ttime (s)\n"
  line_fmt   = "%d\t%d\t%8d\t%5d\t%d\t%10d\t%10d\t%.3f\n"
else
  header_fmt = "nv\tno\tnl       \ttime (s)\n"
  line_fmt   = "%d\t%d\t%8d\t%.3f\n"
end

bench(arg[1], arg[2], arg[3], arg[4])


