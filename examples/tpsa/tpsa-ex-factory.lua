local factory = require "factory"

local nv,no = 3,3
local t

-- HOW TO: factory usage; documentation and example; see below

-- DOCUMENTATION ---------------------------------------------------------------
--------------------------------------------------------------------------------
-- 1) setup with a loaded module and nv,no;
--    -- a) load the module yourself
local berz = require "lib.tpsaBerz"
factory.setup(berz,nv,no)
--    -- b) use the tpsa interface
local tpsa = require "lib.tpsa"
tpsa.set_package("ffi")
factory.setup(tpsa)      -- parameters are cached, so no need to specify them if they didn't change

-- 2) factory.new_instance()  -- I know, long name, but... IDE :); you can cache to smth shorter
t = factory.new_instance()  -- empty tpsa, not that useful

-- 3) factory.get_args(function_name)
      -- returns parameters which can be passed directly to tpsa.function_name
      -- according to current setup (mod, nv, no)
local t1, t2, r = factory.get_args("mul")
tpsa.mul(t1,t2,r)

-- 4) factory.read_params([filename])     -- reads params useful for benchmarking
local NV, NO, NL = factory.read_params()  -- from bench-params/one-params.txt by default
     -- #NV == #NO == #NL

-- 5a) factory.ord(ord [, startVal [, increment]])
t = factory.ord(3, 0.5, 0.01)  -- t has ord 3 filled incrementally: .5, .51, .52 ...

-- 5a) factory.ord({ords} [, startVal [, increment]])
t = factory.ord({2,1})  -- ords in any order; default startVal = 1.1, default inc = 0.1

-- 6) factory.full([startVal [, increment]])
t = factory.full()

-- 7) factory.rand([seed])  -- like full, but with random vals; seed is optional
t = factory.rand(os.time())


-- EXAMPLE ---------------------------------------------------------------------
--   Verify the multiplication between mad-ffi and yang
--------------------------------------------------------------------------------
local mad, yang = require "lib.tpsaFFI", require "lib.tpsaYang"
local check = require "check"

factory.setup(mad,nv,no)
local m1, m2, mr = factory.get_args("mul")
mad.mul(m1,m2,mr)

factory.setup(yang)  -- same nv,no
local y1, y2, yr = factory.get_args("mul")
yang.mul(y1,y2,yr)

local eps = 1e-16   --              fun_name   error_type
check.identical(m1,y1,eps,factory.To,"input1", "absolute")
check.identical(m2,y2,eps,factory.To,"input2", "absolute")
check.identical(mr,yr,eps,factory.To,"mul"   , "absolute")



