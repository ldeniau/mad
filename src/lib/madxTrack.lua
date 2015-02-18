local ffi = require('ffi')
local setmetatable, tonumber, typeof = setmetatable, tonumber, ffi.typeof

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local madxLib = ffi.load(PATH .. '/madx-track/libmadx-track.so')

ffi.cdef[[
// TODO
]]

local M = {}

-- TODO

return M