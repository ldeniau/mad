local test = {}

function test:self(ut)
    require"mad.core.unitTest".addModuleToTest"mad.lang.lambda.math"
    require"mad.core.unitTest".addModuleToTest"mad.lang.lambda.table"
    require"mad.core.unitTest".addModuleToTest"mad.lang.lambda.string"
end

function test:setUp()
    self.module = require"mad.lang.lambda"
    self.tbl1 = self.module( function() return 1 end )
    self.tblhello = self.module( function() return "hello" end )
    self.tbl1cp = self.module( function() return 1 end )
    self.tbl2 = self.module( function() return 2 end )
end

function test:tearDown()
    self.module = nil
    self.tbl1 = nil
    self.tblhello = nil
    self.tbl1cp = nil
    self.tbl2 = nil
end

function test:is_lambda(ut)
    ut:equals(is_lambda(self.tbl1), true)
    ut:equals(is_lambda{ __lambda = function() return false end }, true)
    ut:equals(is_lambda{ __lambda = 1 }, false)
    ut:equals(is_lambda{}, false)
    ut:equals(is_lambda(function() return true end), false)
    ut:equals(is_lambda(1), false)
    ut:equals(is_lambda("fg3e"), false)
    ut:equals(is_lambda(nil), false)
end

function test:tonumber(ut)
    ut:equals(tonumber({}),nil)
    ut:equals(tonumber("h"),nil)
    ut:equals(tonumber("hjioj"),nil)
    ut:equals(tonumber(function() return 1 end),nil)
    ut:equals(tonumber(true),nil)
    ut:equals(tonumber(),nil)
    ut:equals(tonumber("1"),1)
    ut:equals(tonumber(1),1)
    ut:equals(tonumber(self.module(function() return 1 end)),1)
    ut:fails(tonumber,{},16)
    ut:equals(tonumber("h",16),nil)
    ut:equals(tonumber("hjioj",16),nil)
    ut:equals(tonumber("a",16),10)
    ut:equals(tonumber("abc",16),2748)
    ut:fails(tonumber,function() return 1 end,16)
    ut:fails(tonumber,true,16)
    ut:equals(tonumber("10",16),16)
    ut:equals(tonumber(1,16),1)
    ut:equals(tonumber(self.module(function() return 1 end),16),1)
end

function test:ctor(ut)
    local lambda = self.module
    local l = lambda()
    ut:equals(l(), nil)
    ut:equals(l.__lambda(), nil)
    l = lambda(1)
    ut:equals(l(), 1)
    ut:equals(l.__lambda(), 1)
    l = lambda(function () return 2 end)
    ut:equals(l(), 2)
    ut:equals(l.__lambda(), 2)
    l = lambda(function (a) return a end)
    ut:equals(l(2), 2)
    ut:equals(l.__lambda(2), 2)
    l = lambda(function (a,b) return a+b end)
    ut:equals(l(2,3), 5)
    ut:equals(l.__lambda(2,3), 5)
    l = lambda(function (a,b) return a+b,a-b end)
    local a, b = l(2,2)
    ut:equals(a, 4)
    ut:equals(b, 0)
    a, b = l.__lambda(2,2)
    ut:equals(a, 4)
    ut:equals(b, 0)
end

function test:__add(ut)
    ut:equals(self.tbl1+1, 2)
    ut:equals(self.tbl1+self.tbl1cp, 2)
    ut:equals(1+self.tbl1, 2)
    ut:equals(1+1, 2)
end

function test:__sub(ut)
    ut:equals(self.tbl1-1, 0)
    ut:equals(self.tbl1-self.tbl1cp, 0)
    ut:equals(1-self.tbl1, 0)
    ut:equals(1-1, 0)
end

function test:__mul(ut)
    ut:equals(self.tbl1*2, 2)
    ut:equals(self.tbl1*self.tbl2, 2)
    ut:equals(2*self.tbl1, 2)
    ut:equals(1*2, 2)
end

function test:__div(ut)
    ut:equals(self.tbl1/2, 0.5)
    ut:equals(self.tbl1/self.tbl2, 0.5)
    ut:equals(1/self.tbl2, 0.5)
    ut:equals(1/2, 0.5)
end

function test:__mod(ut)
    ut:equals(self.tbl1%1, 0)
    ut:equals(self.tbl1%self.tbl1cp, 0)
    ut:equals(1%self.tbl1, 0)
    ut:equals(1%1, 0)
end

function test:__pow(ut)
    ut:equals(self.tbl2^2, 4)
    ut:equals(self.tbl2^self.tbl2, 4)
    ut:equals(2^self.tbl2, 4)
    ut:equals(2^2, 4)
end

function test:__concat(ut)
    ut:equals(self.tblhello.."h", "helloh")
    ut:equals(self.tblhello..self.tblhello, "hellohello")
    ut:equals("h"..self.tblhello, "hhello")
    ut:equals("h".."h","hh")
end

function test:__unm(ut)
    ut:equals(-self.tbl1, -1)
end

function test:__lt(ut)
    ut:equals(self.tbl1<1, false)
    ut:equals(self.tbl1<self.tbl1cp, false)
    ut:equals(1<self.tbl1, false)
    ut:equals(1<1, false)
    ut:equals(self.tbl1<2, true)
    ut:equals(self.tbl1<self.tbl2, true)
    ut:equals(1<self.tbl2, true)
    ut:equals(1<2, true)
end

function test:__leq(ut)
    ut:equals(self.tbl1<=0, false)
    ut:equals(self.tbl2<=self.tbl1cp, false)
    ut:equals(2<=self.tbl1, false)
    ut:equals(2<=1, false)
    ut:equals(self.tbl1<=1, true)
    ut:equals(self.tbl1<=self.tbl1cp, true)
    ut:equals(1<=self.tbl1, true)
    ut:equals(1<=1, true)
end

function test:__gt(ut)
    ut:equals(self.tbl1>1, false)
    ut:equals(self.tbl1>self.tbl1cp, false)
    ut:equals(1>self.tbl1, false)
    ut:equals(1>1, false)
    ut:equals(self.tbl2>1, true)
    ut:equals(self.tbl2>self.tbl1, true)
    ut:equals(2>self.tbl1, true)
    ut:equals(2>1, true)
end

function test:__geq(ut)
    ut:equals(self.tbl1>=2, false)
    ut:equals(self.tbl1>=self.tbl2, false)
    ut:equals(1>=self.tbl2, false)
    ut:equals(1>=2, false)
    ut:equals(self.tbl1>=1, true)
    ut:equals(self.tbl1>=self.tbl1cp, true)
    ut:equals(1>=self.tbl1, true)
    ut:equals(1>=1, true)
end

function test:__len(ut)
    local tbl = { 2,3,4 }
    local tbltbl = self.module( function () return tbl end )
    ut:equals(#tbltbl, 3)
    tbl = { 5,6,7,8 }
    ut:equals(#tbltbl, 4)
end

function test:__index(ut)
    local tbl = { 2,3,4 }
    local tbltbl = self.module( function () return tbl end )
    ut:equals(tbltbl[1], 2)
    ut:equals(tbltbl[2], 3)
    ut:equals(tbltbl[3], 4)
    ut:equals(tbltbl[4], nil)
    tbl = { 5,6,7,8 }
    ut:equals(tbltbl[1], 5)
    ut:equals(tbltbl[2], 6)
    ut:equals(tbltbl[3], 7)
    ut:equals(tbltbl[4], 8)
end

function test:__newindex(ut)
    local tbl = { 2,3,4 }
    local tbltbl = self.module( function () return tbl end )
    ut:equals(tbltbl[1], 2)
    ut:equals(tbltbl[2], 3)
    ut:equals(tbltbl[3], 4)
    ut:equals(tbltbl[4], nil)
    tbltbl[1] = "hello"
    ut:equals(tbltbl[1], "hello")
    ut:equals(tbl[1], "hello")
    ut:equals(tbltbl[2], 3)
    ut:equals(tbltbl[3], 4)
    ut:equals(tbltbl[4], nil)
end

function test:__call(ut)
    local tbl = { 2,3,4 }
    local l = ut:succeeds(self.module, function () return tbl end )
    ut:equals(l()[1], 2)
    ut:equals(l()[2], 3)
    ut:equals(l()[3], 4)
    ut:equals(l()[4], nil)
    l()[1] = "hello"
    ut:equals(l()[1], "hello")
    ut:equals(tbl[1], "hello")
    ut:equals(l()[2], 3)
    ut:equals(l()[3], 4)
    ut:equals(l()[4], nil)
    tbl = { 5,6,7 }
    ut:equals(l()[1], 5)
    ut:equals(tbl[1], 5)
    ut:equals(l()[2], 6)
    ut:equals(l()[3], 7)
    ut:equals(l()[4], nil)
    l = ut:succeeds(self.module, function (a,b) return a+b end )
    ut:equals(l(1,2),3)
    ut:fails(l,1)
end

function test:__tostring(ut)
    local tbl = self.module( function () return "hello" end )
    ut:equals(tostring(tbl), "hello")
end

function test:__ipairs(ut)
    local tbl = { 2,3,4 }
    local count = 0
    local tbltbl = self.module( function () return tbl end )
    for i,v in ipairs(tbltbl) do
        ut:equals(v, tbl[i])
        count = count + 1
    end
    ut:equals(count, 3)
end

function test:__pairs(ut)
    local tbl = { a=2,[2] = 3,4 }
    local count = 0
    local tbltbl = self.module( function () return tbl end )
    for i,v in pairs(tbltbl) do
        ut:equals(v, tbl[i])
        count = count + 1
    end
    ut:equals(count, 3)
end

return test
