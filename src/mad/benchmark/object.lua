local object = require"mad.object"

print"Benchmarking how fast one can create objects and how much memory they require"

local n = 10000

do
    local obj1 = object
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj2 = obj1 ""
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("1st level, name = ''")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj3 = obj2 ""
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("2nd level, name = ''")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3 = obj2 ""
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj4 = obj3 ""
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("3rd level, name = ''")
    print("  Average memory used: "..tostring(total*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj2 = obj1 "obj2"
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("1st level, name = 'obj2'")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj3 = obj2 "obj3"
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("2nd level, name = 'obj3'")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj4 = obj3 "obj4"
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("3rd level, name = 'obj4'")
    print("  Average memory used: "..tostring(total*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1 }
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj2 = obj1 "obj2" { two = 2 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("1st level, name = 'obj2', 1 object per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj3 = obj2 "obj3" { three = 3 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("2nd level, name = 'obj3', 1 object per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3 = obj2 "obj3" { three = 3 }
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj4 = obj3 "obj4" { four = 4 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("3rd level, name = 'obj4', 1 object per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj2 = obj1 "obj2" { two = 2, two2 = 2 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("1st level, name = 'obj2', 2 objects per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj3 = obj2 "obj3" { three = 3, three3 = 3 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("2nd level, name = 'obj3', 2 objects per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3 }
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj4 = obj3 "obj4" { four = 4, four4 = 4 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("3rd level, name = 'obj4', 2 objects per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("1st level, name = 'obj2', 3 objects per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("2nd level, name = 'obj3', 3 objects per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = collectgarbage"count"
        obj4 = obj3 "obj4" { four = 4, four4 = 4, four44 = 4 }
        stop = collectgarbage"count"
        total = total + stop - start
    end
    print("3rd level, name = 'obj4', 3 objects per level")
    print("  Average memory used: "..tostring(total*1024/n))
end

----------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------
do
    local obj1 = object
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj2 = obj1 ""
        stop = os.clock()
        total = total + stop - start
    end
    print("1st level, name = ''")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj3 = obj2 ""
        stop = os.clock()
        total = total + stop - start
    end
    print("2nd level, name = ''")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object
    local obj2 = obj1 ""
    local obj3 = obj2 ""
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj4 = obj3 ""
        stop = os.clock()
        total = total + stop - start
    end
    print("3rd level, name = ''")
    print("  Average speed: "..tostring(total/n))
end

----------------------------------------------------------------------

do
    local obj1 = object
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj2 = obj1 "obj2"
        stop = os.clock()
        total = total + stop - start
    end
    print("1st level, name = 'obj2'")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj3 = obj2 "obj3"
        stop = os.clock()
        total = total + stop - start
    end
    print("2nd level, name = 'obj3'")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object
    local obj2 = obj1 "obj2"
    local obj3 = obj2 "obj3"
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj4 = obj3 "obj4"
        stop = os.clock()
        total = total + stop - start
    end
    print("3rd level, name = 'obj4'")
    print("  Average speed: "..tostring(total/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1 }
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj2 = obj1 "obj2" { two = 2 }
        stop = os.clock()
        total = total + stop - start
    end
    print("1st level, name = 'obj2', 1 object per level")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj3 = obj2 "obj3" { three = 3 }
        stop = os.clock()
        total = total + stop - start
    end
    print("2nd level, name = 'obj3', 1 object per level")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object { one = 1 }
    local obj2 = obj1 "obj2" { two = 2 }
    local obj3 = obj2 "obj3" { three = 3 }
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj4 = obj3 "obj4" { four = 4 }
        stop = os.clock()
        total = total + stop - start
    end
    print("3rd level, name = 'obj4', 1 object per level")
    print("  Average speed: "..tostring(total/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj2 = obj1 "obj2" { two = 2, two2 = 2 }
        stop = os.clock()
        total = total + stop - start
    end
    print("1st level, name = 'obj2', 2 objects per level")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj3 = obj2 "obj3" { three = 3, three3 = 3 }
        stop = os.clock()
        total = total + stop - start
    end
    print("2nd level, name = 'obj3', 2 objects per level")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object { one = 1, one1 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3 }
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj4 = obj3 "obj4" { four = 4, four4 = 4 }
        stop = os.clock()
        total = total + stop - start
    end
    print("3rd level, name = 'obj4', 2 objects per level")
    print("  Average speed: "..tostring(total/n))
end

----------------------------------------------------------------------

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
        stop = os.clock()
        total = total + stop - start
    end
    print("1st level, name = 'obj2', 3 objects per level")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
        stop = os.clock()
        total = total + stop - start
    end
    print("2nd level, name = 'obj3', 3 objects per level")
    print("  Average speed: "..tostring(total/n))
end

do
    local obj1 = object { one = 1, one1 = 1, one11 = 1 }
    local obj2 = obj1 "obj2" { two = 2, two2 = 2, two22 = 2 }
    local obj3 = obj2 "obj3" { three = 3, three3 = 3, three33 = 3 }
    local obj4, start, stop
    local total = 0
    for i = 1, n do
        start = os.clock()
        obj4 = obj3 "obj4" { four = 4, four4 = 4, four44 = 4 }
        stop = os.clock()
        total = total + stop - start
    end
    print("3rd level, name = 'obj4', 3 objects per level")
    print("  Average speed: "..tostring(total/n))
end

----------------------------------------------------------------------
















