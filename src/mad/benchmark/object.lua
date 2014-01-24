local object = require"mad.object"

print"Benchmarking how fast one can create elements"

local n = 1000000

do
    local obj1 = object
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 ""
    end
    stop = os.clock()
    print("1st level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 ""
    end
    stop = os.clock()
    print("2nd level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3 = obj2 ""
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 ""
    end
    stop = os.clock()
    print("3rd level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2"
    end
    stop = os.clock()
    print("1st level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3"
    end
    stop = os.clock()
    print("2nd level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4"
    end
    stop = os.clock()
    print("3rd level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1 }
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2 }
    end
    stop = os.clock()
    print("1st level, 1 element per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" { three = 3 }
    end
    stop = os.clock()
    print("2nd level, 1 element per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3 = obj2 "obj3" { three = 3 }
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" { four = 4 }
    end
    stop = os.clock()
    print("3rd level, 1 element per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    end
    stop = os.clock()
    print("1st level, 2 elements per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" { three = 3, three3 = 3 }
    end
    stop = os.clock()
    print("2nd level, 2 elements per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3 }
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" { four = 4, four4 = 4 }
    end
    stop = os.clock()
    print("3rd level, 2 elements per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------
--[[
do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    end
    stop = os.clock()
    print("1st level, 3 elements per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    end
    stop = os.clock()
    print("2nd level, 3 elements per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = os.clock()
    print("3rd level, 3 elements per level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2 }
    end
    stop = os.clock()
    print("1st level, 1 element only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object 
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" { three = 3 }
    end
    stop = os.clock()
    print("2nd level, 1 element only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" { four = 4 }
    end
    stop = os.clock()
    print("3rd level, 1 element only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    end
    stop = os.clock()
    print("1st level, 2 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" { three = 3, three3 = 3 }
    end
    stop = os.clock()
    print("2nd level, 2 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2" 
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" { four = 4, four4 = 4 }
    end
    stop = os.clock()
    print("3rd level, 2 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    end
    stop = os.clock()
    print("1st level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    end
    stop = os.clock()
    print("2nd level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = os.clock()
    print("3rd level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5, start, stop
    start = os.clock()
    for i = 1, n do
        obj5 = obj4 "obj5" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = os.clock()
    print("4th level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6, start, stop
    start = os.clock()
    for i = 1, n do
        obj6 = obj5 "obj6" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = os.clock()
    print("5th level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7, start, stop
    start = os.clock()
    for i = 1, n do
        obj7 = obj6 "obj7" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = os.clock()
    print("6th level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7 = obj6 "obj7"
    local obj8, start, stop
    start = os.clock()
    for i = 1, n do
        obj8 = obj7 "obj8" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = os.clock()
    print("7th level, 3 elements only last level")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end
]]
----------------------------------------------------------------------


do
    local obj1 = object
    local obj2, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" (elem)
    end
    stop = os.clock()
    print("1st level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj3 = obj2 "obj3" (elem)
    end
    stop = os.clock()
    print("2nd level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj4 = obj3 "obj4" (elem)
    end
    stop = os.clock()
    print("3rd level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj5 = obj4 "obj5" (elem)
    end
    stop = os.clock()
    print("4th level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj6 = obj5 "obj6" (elem)
    end
    stop = os.clock()
    print("5th level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj7 = obj6 "obj7" (elem)
    end
    stop = os.clock()
    print("6th level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7 = obj6 "obj7"
    local obj8, start, stop
    local elem = { two = 2, two2 = 2, two22 = 2 }
    start = os.clock()
    for i = 1, n do
        obj8 = obj7 "obj8" (elem)
    end
    stop = os.clock()
    print("7th level, 3 elements only last level, table created outside of loop")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------
n = 1000000000

do
    local obj1 = object
    local obj2, start, stop, dummy
    local elem = { two = 2, two2 = 2, two22 = 2 }
    obj2 = obj1 "obj2" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj2:get("two")
    end
    stop = os.clock()
    print("1st level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop, dummy
    obj3 = obj2 "obj3" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj3:get("two")
    end
    stop = os.clock()
    print("2nd level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop, dummy
    obj4 = obj3 "obj4" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj4:get("two")
    end
    stop = os.clock()
    print("3rd level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5, start, stop, dummy
    obj5 = obj4 "obj5" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj5:get("two")
    end
    stop = os.clock()
    print("4th level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6, start, stop, dummy
    obj6 = obj5 "obj6" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj6:get("two")
    end
    stop = os.clock()
    print("5th level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7, start, stop, dummy
    obj7 = obj6 "obj7" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj7:get("two")
    end
    stop = os.clock()
    print("6th level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7 = obj6 "obj7"
    local obj8, start, stop, dummy
    obj8 = obj7 "obj8" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj8:get("two")
    end
    stop = os.clock()
    print("7th level, get element in self")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------
----------------------------------------------------------------------


do
    local obj1 = object
    local obj2, start, stop, dummy
    local elem = { two = 2, two2 = 2, two22 = 2 }
    obj2 = obj1 "obj2" (elem)
    start = os.clock()
    for i = 1, n do
        dummy = obj2:get("two")
    end
    stop = os.clock()
    print("1st level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3, start, stop, dummy
    obj3 = obj2 "obj3"
    start = os.clock()
    for i = 1, n do
        dummy = obj3:get("two")
    end
    stop = os.clock()
    print("2nd level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4, start, stop, dummy
    obj4 = obj3 "obj4"
    start = os.clock()
    for i = 1, n do
        dummy = obj4:get("two")
    end
    stop = os.clock()
    print("3rd level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5, start, stop, dummy
    obj5 = obj4 "obj5"
    start = os.clock()
    for i = 1, n do
        dummy = obj5:get("two")
    end
    stop = os.clock()
    print("4th level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6, start, stop, dummy
    obj6 = obj5 "obj6"
    start = os.clock()
    for i = 1, n do
        dummy = obj6:get("two")
    end
    stop = os.clock()
    print("5th level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7, start, stop, dummy
    obj7 = obj6 "obj7"
    start = os.clock()
    for i = 1, n do
        dummy = obj7:get("two")
    end
    stop = os.clock()
    print("6th level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7 = obj6 "obj7"
    local obj8, start, stop, dummy
    obj8 = obj7 "obj8"
    start = os.clock()
    for i = 1, n do
        dummy = obj8:get("two")
    end
    stop = os.clock()
    print("7th level, get element in top")
    print("  Average speed: "..tostring(n/(stop-start)).." objects per second")
end

----------------------------------------------------------------------


do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7 = obj6 "obj7"
    local obj8, start, stop, dummy
    obj8 = obj7 "obj8"
    start = os.clock()
    for i = 1, n do
        dummy = obj8:get("two")
    end
    stop = os.clock()
    print("7th level, get element in top")
    print("  get:   "..tostring(n/(stop-start)).." elements per second")
    start = os.clock()
    for i = 1, n do
        dummy = obj8["two"]
    end
    stop = os.clock()
    print("  [key]: "..tostring(n/(stop-start)).." elements per second")
end


----------------------------------------------------------------------


do
    local elem = { two = 2, two2 = 2, two22 = 2 }
    local obj1 = object
    local obj2 = obj1 "obj2" (elem)
    local obj3 = obj2 "obj3"
    local obj4 = obj3 "obj4"
    local obj5 = obj4 "obj5"
    local obj6 = obj5 "obj6"
    local obj7 = obj6 "obj7"
    local obj8, start, stop, dummy
    obj8 = obj7 "obj8"
    n = 10000000
    start = os.clock()
    for i = 1, n do
        obj8:set(i, i)
    end
    stop = os.clock()
    print("7th level, set element in self")
    print("  set:   "..tostring(n/(stop-start)).." elements per second")
    n = 100000000
    start = os.clock()
    for i = 1, n do
        obj8[i] = i
    end
    stop = os.clock()
    print("  [key]: "..tostring(n/(stop-start)).." elements per second")
end











