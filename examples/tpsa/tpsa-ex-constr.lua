local tpsa = require"lib.tpsaFFI"

-- test TPSA constructor
-- {vo={2,2} [, mo={3,3}] [, v={'x', 'px'}] [, ko={1,1}] [, dk=2]}
--local d = tpsa.get_desc{vo={2,2}}

--local d1 = tpsa.get_desc{vo={2,2}, ko={1,1}}
--local d2 = tpsa.get_desc{vo={2,2}, nk=2,ko=1}
--assert(d1 == d2)

--local d1 = tpsa.get_desc{vo={2,2}, mo={3,3}}
--local d2 = tpsa.get_desc{vo={2,2}, mo={3,3}, v={'x','y'}}
--assert(d1 == d2)  -- var names are optional at TPSA level and do not differentiate descriptors

--local d1 = tpsa.get_desc{vo={2,2}, mo={3,3}, v={'x','y'}, ko={1,1}}
--local d2 = tpsa.get_desc{vo={2,2}, mo={3,3}, v={'x','y'}, ko={1,1}, dk=1}
--assert(d1 == d2)  -- dk == max(ko) by default

--local d1 = tpsa.get_desc{vo={2,2,0,0}}
--local d2 = tpsa.get_desc{vo={2,2,0,0}, mo={3,3,0,0}}
--local d3 = tpsa.get_desc{vo={2,2,0,0}, mo={3,3,0,0}, v={'x','px', 'y','py'}}
--assert(d1 ~= d2)  -- map orders extend var orders by allowing higher order cross terms
--                  -- i.e. d^2 x * d px exists in the 2nd case but not in the 1st one
--assert(d2 == d3)  -- var names are optional at TPSA level


-- !! ERROR !! vars at 0 order and knobs do not mix yet
--local d1 = tpsa.get_desc{vo={2,2,0,0}, ko={1,1}}
--local d2 = tpsa.get_desc{vo={2,2,0,0}, mo={3,3,0,0}, v={'x','px', 'y','py'}, ko={1,1}}
--local d3 = tpsa.get_desc{vo={2,2,0,0}, mo={3,3,0,0}, v={'x','px', 'y','py'}, ko={1,1}, dk=1}
--assert(d1 == d2 and d2 == d3)
