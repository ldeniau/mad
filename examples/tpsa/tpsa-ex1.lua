local tpsa = require "lib.tpsa"

local nv, no = 6, 3
--local var_ords = { 2, 2, 2, 2, 0, 0 }  -- EXCEPTION
local var_ords = { 2, 2, 2, 2, 1, 1 }
local knb_ords = { 1,1 }

--[=[

tpsa.init({vars} [, vo [, {knobs} [, ko]]])
tpsa.init({vars}) -> vo -> max vars
tpsa.init({vars}, vo) ->  check: sum vars >= vo >= max vars
tpsa.init({vars}, {knobs}) -> ko = max knobs, check vo >= ko
tpsa.init({vars}, vo, {knobs})
tpsa.init({vars}, vo, {knobs}, ko) -> check: sum knobs >= ko >= max knobs

shortcuts:
tpsa.init(nv,vo) -> {vo ... nv times}
tpsa.init(nv,vo,nk,ko) -> {ko ... nk times}

]=]

tpsa.set_package("ffi")
local t
--t = tpsa.init(nv,no)
--t = tpsa.init(nv,no,#knb_ords,2)
--t = tpsa.init(var_ords, 3)
--t = tpsa.init(var_ords, 3, {2,1,1})
t = tpsa.init(var_ords, 3, {1,1,1}, 4)
t:print()
