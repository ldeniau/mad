local object_mt = {}

object_mt.__call = function (t, o)
    if type(o) == "string" then
      return function (so)
        local t, s = t, o
        so._name = s
        return object_mt.__call(t, so)
      end
    end

    t.__index = t
    t.__call  = object_mt.__call
    return setmetatable(o, t)
  end

local object = setmetatable({ _name = "object" }, object_mt)






-- test

local print_obj = function (o)
  print("o = ", o)
  print("o._name = ", o._name)
  local mt = getmetatable(o)
  if mt then
    print("o._mt = ", mt)
    print("o._mt._name = ", mt._name)
  end
end

print("object_mt = ", object_mt)

print_obj(object)

local bend = object "bend" { len = 2 }
local quad = object "quad" { len = 1 }

local mb = bend "mb" { at = 1 }
local mq = quad "mq" { at = 2 }

--[[
mb.r1: bend;

mb.r1 = bend "mb.r1" {}
--]]
--[[
local seq = sequence {
  len = 10,
  bend "mb" { at = 1 },
  quad "mq" { at = 2 }
}
--]]

quad.strengh = 10
quad["strengh"] = 10
mb1["r8"]=
"mb1.r8"

--[[
seq: sequence, len=10;
  mb: bend, at = 1;
  mq: quad, at = 2;
endsequence 
--]]

print_obj(bend)
print_obj(mb)

print_obj(quad)
print_obj(mq)

print("name = ", mb._name, "at = ", mb.at, "len = ", mb.len)
print("name = ", mq._name, "at = ", mq.at, "len = ", mq.len)
