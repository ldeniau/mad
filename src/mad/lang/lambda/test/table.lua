local test = {}

function test:setUp()
    self.lambda = require"mad.lang.lambda"
end

function test:tearDown()
    self.lambda = nil
end

function test:tconcat (ut)
    local tbl = {1,"2",3,"45"}
    local str = ut:succeeds(table.concat, tbl)
    ut:equals(str,"12345")
    str = ut:succeeds(table.concat, tbl, " ")
    ut:equals(str,"1 2 3 45")
    str = ut:succeeds(table.concat, tbl, "", 2)
    ut:equals(str,"2345")
    str = ut:succeeds(table.concat, tbl, "", 2, 3)
    ut:equals(str,"23")
    
    tbl = self.lambda{1,"2",3,"45"}
    str = ut:succeeds(table.concat, tbl)
    ut:equals(str,"12345")
    str = ut:succeeds(table.concat, tbl, " ")
    ut:equals(str,"1 2 3 45")
    str = ut:succeeds(table.concat, tbl, "", 2)
    ut:equals(str,"2345")
    str = ut:succeeds(table.concat, tbl, "", 2, 3)
    ut:equals(str,"23")
    
    tbl = self.lambda(self.lambda{1,"2",3,"45"})
    str = ut:succeeds(table.concat, tbl)
    ut:equals(str,"12345")
    str = ut:succeeds(table.concat, tbl, " ")
    ut:equals(str,"1 2 3 45")
    str = ut:succeeds(table.concat, tbl, "", 2)
    ut:equals(str,"2345")
    str = ut:succeeds(table.concat, tbl, "", 2, 3)
    ut:equals(str,"23")
    
    tbl = self.lambda{1,"2",3,"45"}
    str = ut:succeeds(table.concat, tbl, self.lambda" ")
    ut:equals(str,"1 2 3 45")
    str = ut:succeeds(table.concat, tbl, self.lambda"", 2)
    ut:equals(str,"2345")
    str = ut:succeeds(table.concat, tbl, self.lambda"", 2, 3)
    ut:equals(str,"23")
    
    tbl = self.lambda{1,"2",3,"45"}
    str = ut:succeeds(table.concat, tbl, self.lambda" ")
    ut:equals(str,"1 2 3 45")
    str = ut:succeeds(table.concat, tbl, self.lambda"", self.lambda(2))
    ut:equals(str,"2345")
    str = ut:succeeds(table.concat, tbl, self.lambda"", self.lambda(2), self.lambda(3))
    ut:equals(str,"23")
end

function test:tinsert (ut)
    local tbl = {1,2,3,4,5}
    ut:succeeds(table.insert,tbl,6)
    ut:equals(tbl[6],6)
    ut:succeeds(table.insert,tbl,1,0)
    ut:equals(tbl[1],0)
    ut:succeeds(table.insert,tbl,3,3)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],2)
    
    tbl = self.lambda({1,2,3,4,5})
    ut:succeeds(table.insert,tbl,6)
    ut:equals(tbl[6],6)
    ut:succeeds(table.insert,tbl,1,0)
    ut:equals(tbl[1],0)
    ut:succeeds(table.insert,tbl,3,3)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],2)
    
    tbl = self.lambda{1,2,3,4,5}
    ut:succeeds(table.insert,tbl,self.lambda(6))
    ut:equals(tbl[6],6)
    ut:succeeds(table.insert,tbl,self.lambda(1),self.lambda(0))
    ut:equals(tbl[1],0)
    ut:succeeds(table.insert,tbl,self.lambda(3),self.lambda(3))
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],2)
    
    tbl = self.lambda(self.lambda({1,2,3,4,5}))
    ut:succeeds(table.insert,tbl,6)
    ut:equals(tbl[6],6)
    ut:succeeds(table.insert,tbl,1,0)
    ut:equals(tbl[1],0)
    ut:succeeds(table.insert,tbl,3,3)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],2)
    
    tbl = self.lambda(self.lambda{1,2,3,4,5})
    ut:succeeds(table.insert,tbl,self.lambda(self.lambda(6)))
    ut:equals(tbl[6],6)
    ut:succeeds(table.insert,tbl,self.lambda(self.lambda(1)),self.lambda(self.lambda(0)))
    ut:equals(tbl[1],0)
    ut:succeeds(table.insert,tbl,self.lambda(self.lambda(3)),self.lambda(self.lambda(3)))
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],2)
end

function test:tremove (ut)
    local tbl = {1,2,3,4,5}
    ut:succeeds(table.remove,tbl)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],nil)
    ut:succeeds(table.remove,tbl,2)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],3)
    ut:equals(tbl[3],4)
    ut:equals(tbl[4],nil)
    ut:equals(tbl[5],nil)
    
    tbl = self.lambda{1,2,3,4,5}
    ut:succeeds(table.remove,tbl)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],nil)
    ut:succeeds(table.remove,tbl,2)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],3)
    ut:equals(tbl[3],4)
    ut:equals(tbl[4],nil)
    ut:equals(tbl[5],nil)
    
    tbl = self.lambda(self.lambda{1,2,3,4,5})
    ut:succeeds(table.remove,tbl)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],nil)
    ut:succeeds(table.remove,tbl,2)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],3)
    ut:equals(tbl[3],4)
    ut:equals(tbl[4],nil)
    ut:equals(tbl[5],nil)
    
    tbl = {1,2,3,4,5}
    ut:succeeds(table.remove,tbl,self.lambda(#tbl))
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],nil)
    ut:succeeds(table.remove,tbl,self.lambda(2))
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],3)
    ut:equals(tbl[3],4)
    ut:equals(tbl[4],nil)
    ut:equals(tbl[5],nil)
end

function test:tsort (ut)
    local tbl = {5,4,3,2,1}
    ut:succeeds(table.sort,tbl)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],5)
    
    tbl = self.lambda{5,4,3,2,1}
    ut:succeeds(table.sort,tbl)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],5)
    
    tbl = self.lambda(self.lambda{5,4,3,2,1})
    ut:succeeds(table.sort,tbl)
    ut:equals(tbl[1],1)
    ut:equals(tbl[2],2)
    ut:equals(tbl[3],3)
    ut:equals(tbl[4],4)
    ut:equals(tbl[5],5)
end

function test:tunpack (ut)
    local tbl = {1,2,3,4,5}
    local a,b,c,d,e = ut:succeeds(table.unpack,tbl)
    ut:equals(a,1)
    ut:equals(b,2)
    ut:equals(c,3)
    ut:equals(d,4)
    ut:equals(e,5)
    
    tbl = self.lambda{1,2,3,4,5}
    a,b,c,d,e = ut:succeeds(table.unpack,tbl)
    ut:equals(a,1)
    ut:equals(b,2)
    ut:equals(c,3)
    ut:equals(d,4)
    ut:equals(e,5)
    
    tbl = self.lambda(self.lambda{1,2,3,4,5})
    a,b,c,d,e = ut:succeeds(table.unpack,tbl)
    ut:equals(a,1)
    ut:equals(b,2)
    ut:equals(c,3)
    ut:equals(d,4)
    ut:equals(e,5)
    
    tbl = {1,2,3,4,5}
    a,b,c,d,e = ut:succeeds(table.unpack,tbl,self.lambda(2))
    ut:equals(a,2)
    ut:equals(b,3)
    ut:equals(c,4)
    ut:equals(d,5)
    ut:equals(e,nil)
    
    tbl = {1,2,3,4,5}
    a,b,c,d,e = ut:succeeds(table.unpack,tbl,self.lambda(2), self.lambda(4))
    ut:equals(a,2)
    ut:equals(b,3)
    ut:equals(c,4)
    ut:equals(d,nil)
    ut:equals(e,nil)
    
    tbl = {1,2,3,4,5}
    a,b,c,d,e = ut:succeeds(table.unpack,tbl,2, self.lambda(4))
    ut:equals(a,2)
    ut:equals(b,3)
    ut:equals(c,4)
    ut:equals(d,nil)
    ut:equals(e,nil)
    
    tbl = {1,2,3,4,5}
    a,b,c,d,e = ut:succeeds(table.unpack,tbl,2, 4)
    ut:equals(a,2)
    ut:equals(b,3)
    ut:equals(c,4)
    ut:equals(d,nil)
    ut:equals(e,nil)
end

return test
