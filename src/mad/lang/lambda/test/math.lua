local test = {}

function test:mabs (ut)
    ut:equals(math.abs(                         1)      ,self.abs(1))
    ut:equals(math.abs(                         -1)     ,self.abs(1))
    ut:equals(math.abs(self.lambda(             1))     ,self.abs(1))
    ut:equals(math.abs(self.lambda(             -1))    ,self.abs(-1))
    ut:equals(math.abs(self.lambda(self.lambda( 1)))    ,self.abs(-1))
    ut:equals(math.abs(self.lambda(self.lambda( -1)))   ,self.abs(-1))
end

function test:macos (ut)
    ut:equals(math.acos(                            1)      ,self.acos(1))
    ut:equals(math.acos(                            -1)     ,self.acos(-1))
    ut:equals(math.acos(self.lambda(                1))     ,self.acos(1))
    ut:equals(math.acos(self.lambda(                -1))    ,self.acos(-1))
    ut:equals(math.acos(self.lambda(self.lambda(    1)))    ,self.acos(1))
    ut:equals(math.acos(self.lambda(self.lambda(    -1)))   ,self.acos(-1))
end

function test:masin (ut)
    ut:equals(math.asin(0),self.asin(0))
    ut:equals(math.asin(self.lambda(0)),self.asin(0))
    ut:equals(math.asin(self.lambda(self.lambda(0))),self.asin(0))
end

function test:matan (ut)
    ut:equals(math.atan(0),self.atan(0))
    ut:equals(math.atan(self.lambda(0)),self.atan(0))
    ut:equals(math.atan(self.lambda(self.lambda(0))),self.atan(0))
end

function test:matan2 (ut)
    ut:equals(math.atan2(0,0),self.atan2(0,0))
    ut:equals(math.atan2(self.lambda(0),0),self.atan2(0,0))
    ut:equals(math.atan2(self.lambda(self.lambda(0)),0),self.atan2(0,0))
    ut:equals(math.atan2(0,-1),self.atan2(0,-1))
    ut:equals(math.atan2(self.lambda(0),-1),self.atan2(0,-1))
    ut:equals(math.atan2(self.lambda(self.lambda(0)),-1),self.atan2(0,-1))
end

function test:mceil (ut)
    ut:equals(math.ceil(0),self.ceil(0))
    ut:equals(math.ceil(self.lambda(0)),self.ceil(0))
    ut:equals(math.ceil(self.lambda(self.lambda(0))),self.ceil(0))
    ut:equals(math.ceil(0.2),self.ceil(0.2))
    ut:equals(math.ceil(self.lambda(0.2)),self.ceil(0.2))
    ut:equals(math.ceil(self.lambda(self.lambda(0.2))),self.ceil(0.2))
end

function test:mcos (ut)
    ut:equals(math.cos(0),self.cos(0))
    ut:equals(math.cos(self.lambda(0)),self.cos(0))
    ut:equals(math.cos(self.lambda(self.lambda(0))),self.cos(0))
    ut:equals(math.cos(math.pi),self.cos(math.pi))
    ut:equals(math.cos(self.lambda(math.pi)),self.cos(math.pi))
    ut:equals(math.cos(self.lambda(self.lambda(math.pi))),self.cos(math.pi))
end

function test:mcosh (ut)
    ut:equals(math.cosh(0),self.cosh(0))
    ut:equals(math.cosh(self.lambda(0)),self.cosh(0))
    ut:equals(math.cosh(self.lambda(self.lambda(0))),self.cosh(0))
    ut:equals(math.cosh(math.pi),self.cosh(math.pi))
    ut:equals(math.cosh(self.lambda(math.pi)),self.cosh(math.pi))
    ut:equals(math.cosh(self.lambda(self.lambda(math.pi))),self.cosh(math.pi))
end

function test:mdeg (ut)
    ut:equals(math.deg(0),self.deg(0))
    ut:equals(math.deg(self.lambda(0)),self.deg(0))
    ut:equals(math.deg(self.lambda(self.lambda(0))),self.deg(0))
    ut:equals(math.deg(math.pi),self.deg(math.pi))
    ut:equals(math.deg(self.lambda(math.pi)),self.deg(math.pi))
    ut:equals(math.deg(self.lambda(self.lambda(math.pi))),self.deg(math.pi))
end

function test:mexp (ut)
    ut:equals(math.deg(0),self.deg(0))
    ut:equals(math.deg(self.lambda(0)),self.deg(0))
    ut:equals(math.deg(self.lambda(self.lambda(0))),self.deg(0))
    ut:equals(math.deg(math.pi),self.deg(math.pi))
    ut:equals(math.deg(self.lambda(math.pi)),self.deg(math.pi))
    ut:equals(math.deg(self.lambda(self.lambda(math.pi))),self.deg(math.pi))
end

function test:mfloor (ut)
    ut:equals(math.floor(0),self.floor(0))
    ut:equals(math.floor(self.lambda(0)),self.floor(0))
    ut:equals(math.floor(self.lambda(self.lambda(0))),self.floor(0))
    ut:equals(math.floor(math.pi),self.floor(math.pi))
    ut:equals(math.floor(self.lambda(math.pi)),self.floor(math.pi))
    ut:equals(math.floor(self.lambda(self.lambda(math.pi))),self.floor(math.pi))
end

function test:mfmod (ut)
    ut:equals(math.fmod(                        0,1),                 self.fmod(0,1))
    ut:equals(math.fmod(self.lambda(            0),1),                self.fmod(0,1))
    ut:equals(math.fmod(self.lambda(self.lambda(0)),1),               self.fmod(0,1))
    ut:equals(math.fmod(                        math.pi,1),           self.fmod(math.pi,1))
    ut:equals(math.fmod(self.lambda(            math.pi),1),          self.fmod(math.pi,1))
    ut:equals(math.fmod(self.lambda(self.lambda(math.pi)),1),         self.fmod(math.pi,1))
end

function test:mfrexp (ut)
    local m,e = ut:succeeds(math.frexp, 0)
    local n,f = ut:succeeds(self.frexp, 0)
    ut:equals(m,n)
    ut:equals(e,f)
    m,e = ut:succeeds(math.frexp, self.lambda(0))
    n,f = ut:succeeds(self.frexp, 0)
    ut:equals(m,n)
    ut:equals(e,f)
    m,e = ut:succeeds(math.frexp, self.lambda(self.lambda(0)))
    n,f = ut:succeeds(self.frexp, 0)
    ut:equals(m,n)
    ut:equals(e,f)
    
    m,e = ut:succeeds(math.frexp, 213)
    n,f = ut:succeeds(self.frexp, 213)
    ut:equals(m,n)
    ut:equals(e,f)
    m,e = ut:succeeds(math.frexp, self.lambda(213))
    n,f = ut:succeeds(self.frexp, 213)
    ut:equals(m,n)
    ut:equals(e,f)
    m,e = ut:succeeds(math.frexp, self.lambda(self.lambda(213)))
    n,f = ut:succeeds(self.frexp, 213)
    ut:equals(m,n)
    ut:equals(e,f)
end

function test:mldexp (ut)
    ut:equals(math.ldexp(                        0,0),                 self.ldexp(0,0))
    ut:equals(math.ldexp(self.lambda(            0),0),                self.ldexp(0,0))
    ut:equals(math.ldexp(self.lambda(self.lambda(0)),0),               self.ldexp(0,0))
    ut:equals(math.ldexp(                        math.pi,1),           self.ldexp(math.pi,1))
    ut:equals(math.ldexp(self.lambda(            math.pi),1),          self.ldexp(math.pi,1))
    ut:equals(math.ldexp(self.lambda(self.lambda(math.pi)),1),         self.ldexp(math.pi,1))
end

function test:mlog (ut)
    ut:equals(math.log(                        0,10),                 self.log(0,10))
    ut:equals(math.log(self.lambda(            0),10),                self.log(0,10))
    ut:equals(math.log(self.lambda(self.lambda(0)),10),               self.log(0,10))
    ut:equals(math.log(                        math.pi,10),           self.log(math.pi,10))
    ut:equals(math.log(self.lambda(            math.pi),10),          self.log(math.pi,10))
    ut:equals(math.log(self.lambda(self.lambda(math.pi)),10),         self.log(math.pi,10))
    
    ut:equals(math.log(                        0),                 self.log(0))
    ut:equals(math.log(self.lambda(            0)),                self.log(0))
    ut:equals(math.log(self.lambda(self.lambda(0))),               self.log(0))
    ut:equals(math.log(                        math.pi),           self.log(math.pi))
    ut:equals(math.log(self.lambda(            math.pi)),          self.log(math.pi))
    ut:equals(math.log(self.lambda(self.lambda(math.pi))),         self.log(math.pi))
    
    ut:equals(math.log(0        ,self.lambda(10)),                 self.log(0,10))
    ut:equals(math.log(math.pi  ,self.lambda(10)),                 self.log(math.pi,10))
end

function test:mmax (ut)
    ut:equals(math.max(                        0,0,1,2),                 self.max(0,0,1,2))
    ut:equals(math.max(self.lambda(            0),0,1,2),                self.max(0,0,1,2))
    ut:equals(math.max(self.lambda(self.lambda(0)),0,1,2),               self.max(0,0,1,2))
    ut:equals(math.max(                        math.pi,1,1,2),           self.max(math.pi,1,1,2))
    ut:equals(math.max(self.lambda(            math.pi),1,1,self.lambda(self.lambda(2))),  self.max(math.pi,1,1,2))
    ut:equals(math.max(self.lambda(self.lambda(math.pi)),1,1,self.lambda(self.lambda(2))), self.max(math.pi,1,1,2))
end

function test:mmin (ut)
    ut:equals(math.min(                        0,0,1,2),                 self.min(0,0,1,2))
    ut:equals(math.min(self.lambda(            0),0,1,2),                self.min(0,0,1,2))
    ut:equals(math.min(self.lambda(self.lambda(0)),0,1,2),               self.min(0,0,1,2))
    ut:equals(math.min(                        math.pi,1,1,2),           self.min(math.pi,1,1,2))
    ut:equals(math.min(self.lambda(            math.pi),1,1,self.lambda(self.lambda(2))),  self.min(math.pi,1,1,2))
    ut:equals(math.min(self.lambda(self.lambda(math.pi)),1,1,self.lambda(self.lambda(2))), self.min(math.pi,1,1,2))
end

function test:mmodf (ut)
    ut:equals(math.modf(0),self.modf(0))
    ut:equals(math.modf(self.lambda(0)),self.modf(0))
    ut:equals(math.modf(self.lambda(self.lambda(0))),self.modf(0))
    ut:equals(math.modf(math.pi),self.modf(math.pi))
    ut:equals(math.modf(self.lambda(math.pi)),self.modf(math.pi))
    ut:equals(math.modf(self.lambda(self.lambda(math.pi))),self.modf(math.pi))
end

function test:mpow (ut)
    ut:equals(math.pow(                        0,0),                 self.pow(0,0))
    ut:equals(math.pow(self.lambda(            0),0),                self.pow(0,0))
    ut:equals(math.pow(self.lambda(self.lambda(0)),0),               self.pow(0,0))
    ut:equals(math.pow(                        math.pi,1),           self.pow(math.pi,1))
    ut:equals(math.pow(self.lambda(            math.pi),1),          self.pow(math.pi,1))
    ut:equals(math.pow(self.lambda(self.lambda(math.pi)),1),         self.pow(math.pi,1))
end

function test:mrad (ut)
    ut:equals(math.rad(0),self.rad(0))
    ut:equals(math.rad(self.lambda(0)),self.rad(0))
    ut:equals(math.rad(self.lambda(self.lambda(0))),self.rad(0))
    ut:equals(math.rad(math.pi),self.rad(math.pi))
    ut:equals(math.rad(self.lambda(math.pi)),self.rad(math.pi))
    ut:equals(math.rad(self.lambda(self.lambda(math.pi))),self.rad(math.pi))
end

function test:mrandom (ut)
    self.randomseed(1)
    local a,b,c,d,e,f = 
        math.random(0,0),
        math.random(self.lambda(0),0),
        math.random(self.lambda(self.lambda(0)),0),
        math.random(math.pi,1),
        math.random(self.lambda(math.pi),1),
        math.random(self.lambda(self.lambda(math.pi)),1)
    self.randomseed(1)
    local aa,bb,cc,dd,ee,ff = 
        self.random(0,0),
        self.random(0,0),
        self.random(0,0),
        self.random(math.pi,1),
        self.random(math.pi,1),
        self.random(math.pi,1)
    ut:equals(a,aa)
    ut:equals(b,bb)
    ut:equals(c,cc)
    ut:equals(d,dd)
    ut:equals(e,ee)
    ut:equals(f,ff)
end

function test:mrandomseed (ut)
    self.randomseed(1)
    local a = self.random()
    math.randomseed(1)
    local b = self.random()
    ut:equals(a,b)
    
    self.randomseed(1)
    a = self.random()
    math.randomseed(self.lambda(1))
    b = self.random()
    ut:equals(a,b)
    
    self.randomseed(1)
    a = self.random()
    math.randomseed(self.lambda(self.lambda(1)))
    b = self.random()
    ut:equals(a,b)
end

function test:msin (ut)
    ut:equals(math.sin(0),self.sin(0))
    ut:equals(math.sin(self.lambda(0)),self.sin(0))
    ut:equals(math.sin(self.lambda(self.lambda(0))),self.sin(0))
    ut:equals(math.sin(math.pi),self.sin(math.pi))
    ut:equals(math.sin(self.lambda(math.pi)),self.sin(math.pi))
    ut:equals(math.sin(self.lambda(self.lambda(math.pi))),self.sin(math.pi))
end

function test:msinh (ut)
    ut:equals(math.sinh(0),self.sinh(0))
    ut:equals(math.sinh(self.lambda(0)),self.sinh(0))
    ut:equals(math.sinh(self.lambda(self.lambda(0))),self.sinh(0))
    ut:equals(math.sinh(math.pi),self.sinh(math.pi))
    ut:equals(math.sinh(self.lambda(math.pi)),self.sinh(math.pi))
    ut:equals(math.sinh(self.lambda(self.lambda(math.pi))),self.sinh(math.pi))
end

function test:msqrt (ut)
    ut:equals(math.sqrt(0),self.sqrt(0))
    ut:equals(math.sqrt(self.lambda(0)),self.sqrt(0))
    ut:equals(math.sqrt(self.lambda(self.lambda(0))),self.sqrt(0))
    ut:equals(math.sqrt(math.pi),self.sqrt(math.pi))
    ut:equals(math.sqrt(self.lambda(math.pi)),self.sqrt(math.pi))
    ut:equals(math.sqrt(self.lambda(self.lambda(math.pi))),self.sqrt(math.pi))
end

function test:mtan (ut)
    ut:equals(math.tan(0),self.tan(0))
    ut:equals(math.tan(self.lambda(0)),self.tan(0))
    ut:equals(math.tan(self.lambda(self.lambda(0))),self.tan(0))
    ut:equals(math.tan(math.pi),self.tan(math.pi))
    ut:equals(math.tan(self.lambda(math.pi)),self.tan(math.pi))
    ut:equals(math.tan(self.lambda(self.lambda(math.pi))),self.tan(math.pi))
end

function test:mtanh (ut)
    ut:equals(math.tanh(0),self.tanh(0))
    ut:equals(math.tanh(self.lambda(0)),self.tanh(0))
    ut:equals(math.tanh(self.lambda(self.lambda(0))),self.tanh(0))
    ut:equals(math.tanh(math.pi),self.tanh(math.pi))
    ut:equals(math.tanh(self.lambda(math.pi)),self.tanh(math.pi))
    ut:equals(math.tanh(self.lambda(self.lambda(math.pi))),self.tanh(math.pi))
end

return test
