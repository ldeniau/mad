local check = require"check-ffi"
local clock = os.clock
local header_fmt = "nv\tno\tnc\tnl\tin_ord\n"
local line_fmt   = "%d\t%d\t%d\t%d\t%f\n"

local function printf(s, ...)
  io.write(s:format(...))
end

local function timeit(fun, To, nl, t)
  local nv, val, start = To.pe[1]-To.ps[1]+1, 3.2, clock()
  for l=1,nl do
    for i=0,#To do
      fun(t, nv, To[i], val)
    end
  end
  return clock() - start
end


local function setup(tpsa, nv, no, is_nffi)
  local vars = {}
  for i=1,nv do vars[i] = no end

  local t = tpsa.init(vars, no)
  if is_nffi then check = require"check.lua" end
  check.setup(tpsa, vars, no)

  return t, check.To
end


local function bench(mod_name, fct_name, filename, is_nffi)
  printf("Usage: luajit pek-pok-bench.lua mod_name fct_name [filename] [is_not_ffi]\n")
  if not filename then filename = fct_name .. "-params.txt" end
  local NV, NO, NL = check.read_params(filename)
  assert(#NV == #NO and #NV == #NL)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)

  local tpsa = require(mod_name)

  local Ts = {}
  for i=1,#NL do
    local t, To, To_shuf = setup(tpsa, NV[i], NO[i], is_nffi)

    Ts[i] = timeit(tpsa[fct_name], To,      NL[i], t)

    printf(line_fmt, NV[i], NO[i], #To, NL[i], Ts[i])
  end
end


bench(arg[1], arg[2], arg[3], arg[4])


