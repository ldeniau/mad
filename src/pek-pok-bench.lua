local check = require"check"
local clock = os.clock
local header_fmt = "nv\tno\tnc\tnl\tin_ord    \trandom\n"
local line_fmt   = "%d\t%d\t%d\t%d\t%f\t%f\n"

local function printf(s, ...)
  io.write(s:format(...))
end

local function shuffled(t)
  -- first do a deep copy
  local res = {}
  for i=0,#t do
    res[i] = {}
    for j=1,#t[i] do
      res[i][j] = t[i][j]
    end
  end

  -- then shuffle it
  local rand = math.random
  for i=#res,0,-1 do
    local k = rand(i)
    res[i], res[k] = res[k], res[i]
  end
  return res
end

local function timeit(fun, To, nl, t)
  local start, val = clock(), 3.2
  for l=1,nl do
    for i=1,#To do
      fun(t, To[i], val)
    end
  end
  return clock() - start
end


local function setup(tpsa, nv, no)
  local vars = check.mono_val(nv, no)
  local t = tpsa.init(vars, no)
  check.setup(tpsa, vars, no)

  return t, check.To, shuffled(check.To)
end


local function bench(mod_name, fct_name, filename)
  printf("Usage: luajit pek-pok-bench.lua mod_name fct_name [filename]\n")
  if not filename then filename = fct_name .. "-params.txt" end
  local NV, NO, NL = check.read_params(filename)
  assert(#NV == #NO and #NV == #NL)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf(header_fmt)

  local tpsa = require(mod_name)

  local Ts = {}
  for i=1,#NL do
    local t, To, To_shuf = setup(tpsa, NV[i], NO[i])

    Ts[i]        = {}
    Ts[i].in_ord = timeit(tpsa[fct_name], To,      NL[i], t)
    check.print(t)
    Ts[i].random = timeit(tpsa[fct_name], To_shuf, NL[i], t)
    check.print(t)


    printf(line_fmt, NV[i], NO[i], #To, NL[i], Ts[i].in_ord, Ts[i].random)
  end
end

bench(arg[1], arg[2], arg[3], arg[4])


