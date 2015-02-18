local test = {}

function test:setUp()
    self.lambda = require"mad.lang.lambda"
    self.a = self.lambda("a")
    self.b = self.lambda("b")
    self.d = self.lambda("d")
    self.two = self.lambda(2)
    self.tru = self.lambda(true)
    self.abc = self.lambda("abc")
end

function test:tearDown()
    self.lambda = nil
    self.a = nil
    self.b = nil
    self.d = nil
    self.two = nil
    self.tru = nil
    self.abc = nil
end

function test:sbyte (ut)
    ut:equals(string.byte(self.a),97)
    ut:equals(string.byte("a"),97)
    ut:equals(string.byte(self.abc),97)
    ut:equals(string.byte("abc"),97)
    ut:equals(string.byte(self.abc,2),98)
    ut:equals(string.byte("abc",2),98)
    local b,c = ut:succeeds(string.byte,self.abc,2,3)
    ut:equals(b,98)
    ut:equals(c,99)
    b,c = ut:succeeds(string.byte,"abc",2,3)
    ut:equals(b,98)
    ut:equals(c,99)
    
    ut:equals(string.byte(self.lambda(self.a)),97)
    ut:equals(string.byte(self.lambda(self.abc)),97)
    ut:equals(string.byte(self.lambda(self.abc),2),98)
    b,c = ut:succeeds(string.byte,self.lambda(self.abc),2,3)
    ut:equals(b,98)
    ut:equals(c,99)
end

function test:sdump (ut)
    local func = function(a,b) return a+b end
    local l = self.lambda(func)
    ut:equals(string.dump(func), string.dump(l))
end

function test:sfind (ut)
    local a,b = ut:succeeds(string.find,"abc","b")
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","b",2)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","b",2,true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","d")
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc","d",2)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc","d",2,true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,self.abc,"b")
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,self.abc,"b",2)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,self.abc,"b",2,true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,self.abc,"d")
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,self.abc,"d",2)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,self.abc,"d",2,true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,"abc",self.b)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc",self.b,2)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc",self.b,2,true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc",self.d)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc",self.d,2)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc",self.d,2,true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,"abc","b",self.two)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","b",self.two,true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","d",self.two)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc","d",self.two,true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,"abc","b",2,self.tru)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","d",2,self.tru)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,self.lambda(self.abc),"b")
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,self.lambda(self.abc),"b",2)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,self.lambda(self.abc),"b",2,true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,self.lambda(self.abc),"d")
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,self.lambda(self.abc),"d",2)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,self.lambda(self.abc),"d",2,true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,"abc",self.lambda(self.b))
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc",self.lambda(self.b),2)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc",self.lambda(self.b),2,true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc",self.lambda(self.d))
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc",self.lambda(self.d),2)
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc",self.lambda(self.d),2,true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,"abc","b",self.lambda(self.two))
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","b",self.lambda(self.two),true)
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","d",self.lambda(self.two))
    ut:equals(a,nil)
    ut:equals(b,nil)
    a,b = ut:succeeds(string.find,"abc","d",self.lambda(self.two),true)
    ut:equals(a,nil)
    ut:equals(b,nil)
    
    a,b = ut:succeeds(string.find,"abc","b",2,self.lambda(self.tru))
    ut:equals(a,2)
    ut:equals(b,2)
    a,b = ut:succeeds(string.find,"abc","d",2,self.lambda(self.tru))
    ut:equals(a,nil)
    ut:equals(b,nil)
end

function test:sformat (ut)
    ut:equals(string.format("abcdefgh"),"abcdefgh")
    ut:equals(string.format("ab%sdefgh", "c"),"abcdefgh")
    ut:equals(string.format("ab%idefgh", 1),"ab1defgh")
    ut:equals(string.format("abcdefgh%d%d%d",1,2,3),"abcdefgh123")
    ut:equals(string.format("%d%s%d%s%d",1,"2",3,"4",5),"12345")
    
    ut:equals(string.format(self.lambda("abcdefgh")),"abcdefgh")
    ut:equals(string.format(self.lambda("ab%sdefgh"), "c"),"abcdefgh")
    ut:equals(string.format(self.lambda("ab%idefgh"), 1),"ab1defgh")
    ut:equals(string.format(self.lambda("abcdefgh%d%d%d"),1,2,3),"abcdefgh123")
    ut:equals(string.format(self.lambda("%d%s%d%s%d"),1,"2",3,"4",5),"12345")
    
    ut:equals(string.format("ab%sdefgh", self.lambda("c")),"abcdefgh")
    ut:equals(string.format("ab%idefgh", self.lambda(1)),"ab1defgh")
    ut:equals(string.format("abcdefgh%d%d%d",self.lambda(1),self.lambda(2),self.lambda(3)),"abcdefgh123")
    ut:equals(string.format("%d%s%d%s%d",self.lambda(1),"2",self.lambda(3),self.lambda("4"),self.lambda(5)),"12345")
    
    ut:equals(string.format(self.lambda(self.lambda("abcdefgh"))),"abcdefgh")
    ut:equals(string.format(self.lambda(self.lambda("ab%sdefgh")), "c"),"abcdefgh")
    ut:equals(string.format(self.lambda(self.lambda("ab%idefgh")), 1),"ab1defgh")
    ut:equals(string.format(self.lambda(self.lambda("abcdefgh%d%d%d")),1,2,3),"abcdefgh123")
    ut:equals(string.format(self.lambda(self.lambda("%d%s%d%s%d")),1,"2",3,"4",5),"12345")
    
    ut:equals(string.format("ab%sdefgh", self.lambda(self.lambda("c"))),"abcdefgh")
    ut:equals(string.format("ab%idefgh", self.lambda(self.lambda(1))),"ab1defgh")
    ut:equals(string.format("abcdefgh%d%d%d",self.lambda(self.lambda(1)),self.lambda(self.lambda(2)),self.lambda(self.lambda(3))),"abcdefgh123")
    ut:equals(string.format("%d%s%d%s%d",self.lambda(self.lambda(1)),"2",self.lambda(self.lambda(3)),self.lambda(self.lambda("4")),self.lambda(self.lambda(5))),"12345")
end

function test:sgmatch (ut)
    local abababab = self.lambda("abababab")
    local count = 0
    for c in string.gmatch("abababab","b") do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
    count = 0
    for c in string.gmatch(abababab,"b") do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
    count = 0
    for c in string.gmatch("abababab",self.b) do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
    count = 0
    for c in string.gmatch(abababab,self.b) do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
    
    count = 0
    for c in string.gmatch(self.lambda(abababab),"b") do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
    count = 0
    for c in string.gmatch("abababab",self.lambda(self.b)) do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
    count = 0
    for c in string.gmatch(self.lambda(abababab),self.lambda(self.b)) do
        ut:equals(c,"b")
        count = count + 1
    end
    ut:equals(count,4)
end

function test:sgsub (ut)
    local s,n = ut:succeeds(string.gsub,"ababababab","b","c")
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,"ababababab","b","c",2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,"ababababab","3","c")
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,self.lambda("ababababab"),"b","c")
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,self.lambda("ababababab"),"b","c",2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,self.lambda("ababababab"),"3","c")
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,"ababababab",self.lambda("b"),"c")
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,"ababababab",self.lambda("b"),"c",2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,"ababababab",self.lambda("3"),"c")
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,"ababababab","b",self.lambda("c"))
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,"ababababab","b",self.lambda("c"),2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,"ababababab","3",self.lambda("c"))
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,"ababababab","b","c",self.lambda(2))
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    
    s,n = ut:succeeds(string.gsub,self.lambda(self.lambda("ababababab")),"b","c")
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,self.lambda(self.lambda("ababababab")),"b","c",2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,self.lambda(self.lambda("ababababab")),"3","c")
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,"ababababab",self.lambda(self.lambda("b")),"c")
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,"ababababab",self.lambda(self.lambda("b")),"c",2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,"ababababab",self.lambda(self.lambda("3")),"c")
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,"ababababab","b",self.lambda(self.lambda("c")))
    ut:equals(s,"acacacacac")
    ut:equals(n,5)
    s,n = ut:succeeds(string.gsub,"ababababab","b",self.lambda(self.lambda("c")),2)
    ut:equals(s,"acacababab")
    ut:equals(n,2)
    s,n = ut:succeeds(string.gsub,"ababababab","3",self.lambda(self.lambda("c")))
    ut:equals(s,"ababababab")
    ut:equals(n,0)
    
    s,n = ut:succeeds(string.gsub,"ababababab","b","c",self.lambda(self.lambda(2)))
    ut:equals(s,"acacababab")
    ut:equals(n,2)
end

function test:slen (ut)
    ut:equals(string.len(self.lambda(self.a)),1)
    ut:equals(string.len(self.lambda(self.abc)),3)
    ut:equals(string.len(self.lambda(self.lambda(123))),3)
    ut:equals(string.len(self.a),1)
    ut:equals(string.len(self.abc),3)
    ut:equals(string.len(self.lambda(123)),3)
    ut:equals(string.len("a"),1)
    ut:equals(string.len("abc"),3)
    ut:equals(string.len("123"),3)
end

function test:slower (ut)
    local aBAbaBABa = self.lambda("aBAbaBABa")
    ut:equals(string.lower(self.lambda(aBAbaBABa)), "ababababa")
    ut:equals(string.lower(aBAbaBABa), "ababababa")
    ut:equals(string.lower("aBAbaBABa"), "ababababa")
end

function test:smatch (ut)
    ut:equals(string.match("ababbbabb", "b+"    ), "b")
    ut:equals(string.match("ababbbabb", "b+", 3 ), "bbb")
    ut:equals(string.match("ababbbabb", "b+", -1), "b")
    
    local ababbbabb = self.lambda("ababbbabb")
    ut:equals(string.match(ababbbabb, "b+"    ), "b")
    ut:equals(string.match(ababbbabb, "b+", 3 ), "bbb")
    ut:equals(string.match(ababbbabb, "b+", -1), "b")
    
    local patt = self.lambda("b+")
    ut:equals(string.match("ababbbabb", patt    ), "b")
    ut:equals(string.match("ababbbabb", patt, 3 ), "bbb")
    ut:equals(string.match("ababbbabb", patt, -1), "b")
    
    ut:equals(string.match("ababbbabb", "b+", self.lambda(nil)), "b")
    ut:equals(string.match("ababbbabb", "b+", self.lambda(3)  ), "bbb")
    ut:equals(string.match("ababbbabb", "b+", self.lambda(-1) ), "b")
    
    ut:equals(string.match("ababbbabb", "d+"    ), nil)
    ut:equals(string.match("ababbbabb", "d+", 3 ), nil)
    ut:equals(string.match("ababbbabb", "d+", -1), nil)
    
    ut:equals(string.match(ababbbabb, "d+"    ), nil)
    ut:equals(string.match(ababbbabb, "d+", 3 ), nil)
    ut:equals(string.match(ababbbabb, "d+", -1), nil)
    
    ut:equals(string.match("dddd", patt    ), nil)
    ut:equals(string.match("dddd", patt, 3 ), nil)
    ut:equals(string.match("dddd", patt, -1), nil)
    
    ut:equals(string.match("ababbbabb", "d+", self.lambda(nil)), nil)
    ut:equals(string.match("ababbbabb", "d+", self.lambda(3)  ), nil)
    ut:equals(string.match("ababbbabb", "d+", self.lambda(-1) ), nil)
    
    ababbbabb = self.lambda(self.lambda("ababbbabb"))
    ut:equals(string.match(ababbbabb, "b+"    ), "b")
    ut:equals(string.match(ababbbabb, "b+", 3 ), "bbb")
    ut:equals(string.match(ababbbabb, "b+", -1), "b")
    
    patt = self.lambda(self.lambda("b+"))
    ut:equals(string.match("ababbbabb", patt    ), "b")
    ut:equals(string.match("ababbbabb", patt, 3 ), "bbb")
    ut:equals(string.match("ababbbabb", patt, -1), "b")
    
    ut:equals(string.match("ababbbabb", "b+", self.lambda(self.lambda(nil))), "b")
    ut:equals(string.match("ababbbabb", "b+", self.lambda(self.lambda(3)  )), "bbb")
    ut:equals(string.match("ababbbabb", "b+", self.lambda(self.lambda(-1) )), "b")
    
    ut:equals(string.match(ababbbabb, "d+"    ), nil)
    ut:equals(string.match(ababbbabb, "d+", 3 ), nil)
    ut:equals(string.match(ababbbabb, "d+", -1), nil)
    
    ut:equals(string.match("dddd", patt    ), nil)
    ut:equals(string.match("dddd", patt, 3 ), nil)
    ut:equals(string.match("dddd", patt, -1), nil)
    
    ut:equals(string.match("ababbbabb", "d+", self.lambda(self.lambda(nil))), nil)
    ut:equals(string.match("ababbbabb", "d+", self.lambda(self.lambda(3)  )), nil)
    ut:equals(string.match("ababbbabb", "d+", self.lambda(self.lambda(-1) )), nil)
end

function test:srep (ut)
    ut:equals(string.rep("abc",0),"")
    ut:equals(string.rep("abc",1),"abc")
    ut:equals(string.rep("abc",2),"abcabc")
    ut:equals(string.rep("abc",0,"d"),"")
    ut:equals(string.rep("abc",1,"d"),"abc")
    ut:equals(string.rep("abc",2,"d"),"abcdabc")
    
    ut:equals(string.rep(self.abc,0),"")
    ut:equals(string.rep(self.abc,1),"abc")
    ut:equals(string.rep(self.abc,2),"abcabc")
    ut:equals(string.rep(self.abc,0,"d"),"")
    ut:equals(string.rep(self.abc,1,"d"),"abc")
    ut:equals(string.rep(self.abc,2,"d"),"abcdabc")
    
    ut:equals(string.rep("abc",self.lambda(0)),"")
    ut:equals(string.rep("abc",self.lambda(1)),"abc")
    ut:equals(string.rep("abc",self.lambda(2)),"abcabc")
    ut:equals(string.rep("abc",self.lambda(0),"d"),"")
    ut:equals(string.rep("abc",self.lambda(1),"d"),"abc")
    ut:equals(string.rep("abc",self.lambda(2),"d"),"abcdabc")
    
    ut:equals(string.rep("abc",0,self.d),"")
    ut:equals(string.rep("abc",1,self.d),"abc")
    ut:equals(string.rep("abc",2,self.d),"abcdabc")
    
    ut:equals(string.rep(self.lambda(self.abc),0),"")
    ut:equals(string.rep(self.lambda(self.abc),1),"abc")
    ut:equals(string.rep(self.lambda(self.abc),2),"abcabc")
    ut:equals(string.rep(self.lambda(self.abc),0,"d"),"")
    ut:equals(string.rep(self.lambda(self.abc),1,"d"),"abc")
    ut:equals(string.rep(self.lambda(self.abc),2,"d"),"abcdabc")
    
    ut:equals(string.rep("abc",self.lambda(self.lambda(0))),"")
    ut:equals(string.rep("abc",self.lambda(self.lambda(1))),"abc")
    ut:equals(string.rep("abc",self.lambda(self.lambda(2))),"abcabc")
    ut:equals(string.rep("abc",self.lambda(self.lambda(0)),"d"),"")
    ut:equals(string.rep("abc",self.lambda(self.lambda(1)),"d"),"abc")
    ut:equals(string.rep("abc",self.lambda(self.lambda(2)),"d"),"abcdabc")
    
    ut:equals(string.rep("abc",0,self.lambda(self.d)),"")
    ut:equals(string.rep("abc",1,self.lambda(self.d)),"abc")
    ut:equals(string.rep("abc",2,self.lambda(self.d)),"abcdabc")
end

function test:sreverse (ut)
    ut:equals(string.reverse("a"),"a")
    ut:equals(string.reverse("abc"),"cba")
    ut:equals(string.reverse("abbbc"),"cbbba")
    ut:equals(string.reverse(self.a),"a")
    ut:equals(string.reverse(self.abc),"cba")
    ut:equals(string.reverse(self.lambda("abbbc")),"cbbba")
    ut:equals(string.reverse(self.lambda(self.a)),"a")
    ut:equals(string.reverse(self.lambda(self.abc)),"cba")
    ut:equals(string.reverse(self.lambda(self.lambda("abbbc"))),"cbbba")
end

function test:ssub (ut)
    ut:equals(string.sub("abcdefghijkl",1), "abcdefghijkl")
    ut:equals(string.sub("abcdefghijkl",3), "cdefghijkl")
    ut:equals(string.sub("abcdefghijkl",3,-2), "cdefghijk")
    ut:equals(string.sub("abcdefghijkl",3,5), "cde")
    
    ut:equals(string.sub(self.lambda("abcdefghijkl"),1), "abcdefghijkl")
    ut:equals(string.sub(self.lambda("abcdefghijkl"),3), "cdefghijkl")
    ut:equals(string.sub(self.lambda("abcdefghijkl"),3,-2), "cdefghijk")
    ut:equals(string.sub(self.lambda("abcdefghijkl"),3,5), "cde")
    
    ut:equals(string.sub("abcdefghijkl",self.lambda(1)), "abcdefghijkl")
    ut:equals(string.sub("abcdefghijkl",self.lambda(3)), "cdefghijkl")
    ut:equals(string.sub("abcdefghijkl",self.lambda(3),-2), "cdefghijk")
    ut:equals(string.sub("abcdefghijkl",self.lambda(3),5), "cde")
    
    ut:equals(string.sub("abcdefghijkl",3,self.lambda(-2)), "cdefghijk")
    ut:equals(string.sub("abcdefghijkl",3,self.lambda(5)), "cde")
    
    ut:equals(string.sub(self.lambda(self.lambda("abcdefghijkl")),1), "abcdefghijkl")
    ut:equals(string.sub(self.lambda(self.lambda("abcdefghijkl")),3), "cdefghijkl")
    ut:equals(string.sub(self.lambda(self.lambda("abcdefghijkl")),3,-2), "cdefghijk")
    ut:equals(string.sub(self.lambda(self.lambda("abcdefghijkl")),3,5), "cde")
    
    ut:equals(string.sub("abcdefghijkl",self.lambda(self.lambda(1))), "abcdefghijkl")
    ut:equals(string.sub("abcdefghijkl",self.lambda(self.lambda(3))), "cdefghijkl")
    ut:equals(string.sub("abcdefghijkl",self.lambda(self.lambda(3)),-2), "cdefghijk")
    ut:equals(string.sub("abcdefghijkl",self.lambda(self.lambda(3)),5), "cde")
    
    ut:equals(string.sub("abcdefghijkl",3,self.lambda(self.lambda(-2))), "cdefghijk")
    ut:equals(string.sub("abcdefghijkl",3,self.lambda(self.lambda(5))), "cde")
end

function test:supper (ut)
    local aBAbaBABa = self.lambda("aBAbaBABa")
    ut:equals(string.upper(aBAbaBABa), "ABABABABA")
    ut:equals(string.upper(self.lambda(aBAbaBABa)), "ABABABABA")
    ut:equals(string.upper("aBAbaBABa"), "ABABABABA")
end

return test
