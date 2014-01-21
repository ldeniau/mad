-- ctor
local obj = cls'id' {key=val, ...} -- ctor, type=object for 1st level
-- equivalent to
local obj = cls'id'		-- create the new instance
obj { key=val, ...} 		-- *set* properties of obj

-- ctor/set
local magnet = object 'magnet'
local bend   = magnet 'bend' { key = val }
local mb = bend 'mb' { key2 = val2 }
local mq = mb:clone'mq'

-- ctor
obj = cls'id' {}		-- new intance of class cls
obj = obj2:clone'id' 		-- clone an object, 1st level (k,v) are copied

-- type
obj:super()			-- get the parent
obj:isa'id'			-- check for parent 'id'
obj:isa(id)			-- check for parent  id

-- read (lookup on all supers)
val = obj.key;
val = obj:get'key'
v1, v2, v3 = obj:get{'k1','k2','k3'}

-- write (stored on first level only, no lookup)
obj.key = val
obj:set('key',val)
obj:set{key=val,...} 		-- must not already exist

-- construction
obj = cls 'obj' {key=val}

-- MAD-X translation --

MB: BEND, key=val, ...; 	-- ctor
-- outside the sequence it creates a class from class BEND
-- inside  the sequence it creates an elements of class BEND

MB, key=val, ...; 		-- update
-- outside the sequence it updates/adds values of/to the element
-- inside  the sequence it's an error

-- sequence constructor { type 'name' {properties} }
seq = sequence 'name' {
    MB 'mb' { key = val }, 	-- mb constructor
}

-- set new properties of existing elements
seq:set {
    'mb' = { key = val },
}

-- set new properties of existing elements
seq:insert {
???
}

-- get existing elements
like object
