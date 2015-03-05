local tpsa = require "lib.tpsa"

local nv, no = 6, 3
local var_ords = { 2, 2, 2, 2, 0, 0, 1, 1 }

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

tpsa.init(nv,no,var_ords,knb_ords,mvo,mko)