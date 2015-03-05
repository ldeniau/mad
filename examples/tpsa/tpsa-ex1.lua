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
--tpsa.init(nv,no)
--tpsa.init(nv,no,#knb_ords,2)
local t = tpsa.init(var_ords)
t:print()
