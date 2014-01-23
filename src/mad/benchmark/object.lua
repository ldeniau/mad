local object = require"mad.object"

print"Benchmarking how fast one can create objects and how much memory they require"

local n = 1000

do
    local obj1 = object
    local obj2, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj1 ""
    end
    stop = collectgarbage"count"
    print("1st level, name = ''")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj2 ""
    end
    stop = collectgarbage"count"
    print("2nd level, name = ''")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3 = obj2 ""
    local obj4, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj3 ""
    end
    stop = collectgarbage"count"
    print("3rd level, name = ''")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj1 "obj2"
    end
    stop = collectgarbage"count"
    print("1st level, name = 'obj2'")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj2 "obj3"
    end
    stop = collectgarbage"count"
    print("2nd level, name = 'obj3'")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj3 "obj4"
    end
    stop = collectgarbage"count"
    print("3rd level, name = 'obj4'")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1 }
    local obj2, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj1 "obj2" { two = 2 }
    end
    stop = collectgarbage"count"
    print("1st level, name = 'obj2', 1 object per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj2 "obj3" { three = 3 }
    end
    stop = collectgarbage"count"
    print("2nd level, name = 'obj3', 1 object per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3 = obj2 "obj3" { three = 3 }
    local obj4, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj3 "obj4" { four = 4 }
    end
    stop = collectgarbage"count"
    print("3rd level, name = 'obj4', 1 object per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj1 "obj2" { two = 2, two2 = 2 }
    end
    stop = collectgarbage"count"
    print("1st level, name = 'obj2', 2 objects per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj2 "obj3" { three = 3, three3 = 3 }
    end
    stop = collectgarbage"count"
    print("2nd level, name = 'obj3', 2 objects per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3 }
    local obj4, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj3 "obj4" { four = 4, four4 = 4 }
    end
    stop = collectgarbage"count"
    print("3rd level, name = 'obj4', 2 objects per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    end
    stop = collectgarbage"count"
    print("1st level, name = 'obj2', 3 objects per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    end
    stop = collectgarbage"count"
    print("2nd level, name = 'obj3', 3 objects per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    local obj4, start, stop
    local obj = {}
    start = collectgarbage"count"
    for i = 1, n do
        obj[#obj+1] = obj3 "obj4" { four = 4, four4 = 4, four44 = 4 }
    end
    stop = collectgarbage"count"
    print("3rd level, name = 'obj4', 3 objects per level")
    print("  Average memory used: "..tostring((stop-start)*1024/n))
end

----------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------
n = 10000000

do
    local obj1 = object
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 ""
    end
    stop = os.clock()
    print("1st level, name = ''")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("2nd level, name = ''")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("3rd level, name = ''")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("1st level, name = 'obj2'")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("2nd level, name = 'obj3'")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("3rd level, name = 'obj4'")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("1st level, name = 'obj2', 1 object per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("2nd level, name = 'obj3', 1 object per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("3rd level, name = 'obj4', 1 object per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("1st level, name = 'obj2', 2 objects per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("2nd level, name = 'obj3', 2 objects per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("3rd level, name = 'obj4', 2 objects per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2, start, stop
    start = os.clock()
    for i = 1, n do
        obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    end
    stop = os.clock()
    print("1st level, name = 'obj2', 3 objects per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("2nd level, name = 'obj3', 3 objects per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
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
    print("3rd level, name = 'obj4', 3 objects per level")
    print("  Average speed: "..tostring((stop-start)*1000000/n).."us")
end

----------------------------------------------------------------------
















