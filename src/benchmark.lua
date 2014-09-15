local clock = os.clock
local check = require "check"

local function mono_val(l, n)
  local a = {}
  for i=1,l do a[i] = n end
  return a
end

local function printf(s, ...)
  io.write(s:format(...))
--  io.flush();
end

local function timeit(fun, nl, t1, t2, r)
  local start = clock()
  for l=1,nl do fun(t1, t2, r) end
  return clock() - start
end

local function fill_ord1(t, nv)
  local m = mono_val(nv, 0)
  t:setCoeff(m, 1.1)
  for i=1,nv do
    m[i] = 1
    t:setCoeff(m, 1.1 + i/10)
    m[i] = 0
  end
end

local function fill_full(t, no)
  -- t:pow(no)
  local b, r, floor = t:cpy(), t:new(), math.floor
  r:setConst(1)

  while no > 0 do
    if no%2==1 then
      r.mul(r, b, t)
      r, t = t, r
      no = no - 1
    end
    b.mul(b, b, t)
    b, t = t, b
    no = no/2
  end
  r:cpy(t)
end

local function setup(tpsa, nv, no)
  local vars, vname = {}, "x%d"
  for i=1,nv do vars[i] = vname:format(i) end

  local t = tpsa.init(vars, no) -- call tpsa constructor, i.e. the module
  fill_ord1(t, nv)
  fill_full(t, no)

  check.setup(tpsa, nv, no)

  return t, t:cpy(), t:new()
end

-- read benchmark input parameters: NV, NO, NL
local function read_params(filename)
  local f = io.open(filename, "r")
  local NV, NO, NL, l = {}, {}, {}, 1

  if not f then
    error("Params file not found: " .. filename)
  else
    while true do
      local nv, no, nl, ts = f:read("*number", "*number", "*number", "*number")
      if not (nv and no and nl) then break end
      assert(nv and no and nl)
      NV[l], NO[l], NL[l] = nv, no, nl
      l = l + 1
    end
    printf("%d lines read from %s.\n", l, filename)
  end
  f:close()
  return NV, NO, NL
end

-- benchmark the speed of fct_name from module mod_name using parameters from filename
local function bench(mod_name, fct_name, filename)
  printf("Usage: luajit benchmark.lua mod_name fct_name [filename]\n")

  if not filename then filename = fct_name .. "-params.txt" end
  local NV, NO, NL = read_params(filename)
  assert(#NV == #NO and #NV == #NL)

  printf("Benchmarking %s -- %s ... \n", mod_name, fct_name)
  printf("nv\tno\tnl\ttime (s)\n")

  local tpsa = require(mod_name)

  local Ts = {}
  for i=1,#NL do
    local t1, t2, r = setup(tpsa, NV[i], NO[i])
    check.print(t1)
    check.print(t2)
    check.print(r)

    Ts[i] = timeit(tpsa[fct_name], NL[i], t1, t2, r)

    check.print(t1)
    check.print(t2)
    check.print(r)

    printf("%d\t%d\t%d\t%.3f\n", NV[i], NO[i], NL[i], Ts[i])
  end

  check.tear_down()
end

bench(arg[1], arg[2], arg[3])


