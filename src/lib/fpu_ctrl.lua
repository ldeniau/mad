local ffi = require('ffi')
local bit = require('bit')
local band, bor, bnot = bit.band, bit.bor, bit.bnot
local rshift, lshift = bit.rshift, bit.lshift

-- to load from relative path, you need the path of the file which requires
-- current module;
-- first get the directory structure: for "foo/bar/baz.lua" it is "foo.bar"
local PATH = (...):match("(.+)%.[^%.]+$") or (...)
PATH:gsub("%.", "/")    -- replace . with / to get "foo/bar" TODO: cross platf
local fpuLib = ffi.load(PATH .. '/fpu-ctrl/libfpu-ctrl.so')

ffi.cdef[[
  unsigned int getcsr();
  void         setcsr(unsigned int csr_value);
]]

local M = {}

local flags2bit = {
  ['FZ']  = 15,                --  Flush To Zero
  ['R+']  = 13,                --  Round Positive
  ['R-']  = 13,                --  Round Negative
  ['RZ']  = 13,                --  Round To Zero
  ['RN']  = 13,                --  Round To Nearest
  ['PM']  = 12,                --  Precision Mask
  ['UM']  = 11,                --  Underflow Mask
  ['OM']  = 10,                --  Overflow Mask
  ['ZM']  = 9,                 --  Divide By Zero Mask
  ['DM']  = 8,                 --  Denormal Mask
  ['IM']  = 7,                 --  Invalid Operation Mask
  ['DAZ'] = 6,                 --  Denormals Are Zero
  ['PE']  = 5,                 --  Precision Flag
  ['UE']  = 4,                 --  Underflow Flag
  ['OE']  = 3,                 --  Overflow Flag
  ['ZE']  = 2,                 --  Divide By Zero Flag
  ['DE']  = 1,                 --  Denormal Flag
  ['IE']  = 0                  --  Invalid Operation Flag
}

local rounding_val = {
  ['RN']  = 0,                 --  Round To Nearest
  ['R-']  = 1,                 --  Round Negative
  ['R+']  = 2,                 --  Round Positive
  ['RZ']  = 3,                 --  Round To Zero
  [ 0  ]  = 'RN',
  [ 1  ]  = 'R-',
  [ 2  ]  = 'R+',
  [ 3  ]  = 'RZ',
}

local flags2name = {
  ['FZ']  =  'Flush To Zero',
  ['R+']  =  'Round Positive',
  ['R-']  =  'Round Negative',
  ['RZ']  =  'Round To Zero',
  ['RN']  =  'Round To Nearest',
  ['PM']  =  'Precision Mask',
  ['UM']  =  'Underflow Mask',
  ['OM']  =  'Overflow Mask',
  ['ZM']  =  'Divide By Zero Mask',
  ['DM']  =  'Denormal Mask',
  ['IM']  =  'Invalid Operation Mask',
  ['DAZ'] =  'Denormals Are Zero',
  ['PE']  =  'Precision Flag',
  ['UE']  =  'Underflow Flag',
  ['OE']  =  'Overflow Flag',
  ['ZE']  =  'Divide By Zero Flag',
  ['DE']  =  'Denormal Flag',
  ['IE']  =  'Invalid Operation Flag'
}

function M.set(flag)
  if not flags2bit[flag] then
    error "Incorrect flag"
  end

  local csr = fpuLib.getcsr()
  if flag:sub(1,1) == 'R' then
    csr = band(csr, bnot(lshift(3,flags2bit[flag])))  -- clear 13,14
    csr = bor (csr, lshift(rounding_val[flag],flags2bit[flag]))
  else
    csr = bor(csr, lshift(1,flags2bit[flag]))
  end
  fpuLib.setcsr(csr)
end

function M.clear(flag)
  if not flags2bit[flag] then
    error "Incorrect flag"
  end

  local csr = fpuLib.getcsr()
  if flag:sub(1,1) == 'R' then
    csr = band(csr, bnot(lshift(3,flags2bit[flag])))  -- clear 13,14
  else
    csr = band(csr, bnot(lshift(1,flags2bit[flag])))
  end
  fpuLib.setcsr(csr)
end

function M.get()
  local flags = {}
  local csr = fpuLib.getcsr()
  for flag,bit in pairs(flags2bit) do
    if bit ~= 13 and bit ~= 14 and
       band(csr, lshift(1,flags2bit[flag])) ~= 0 then
      flags[flag] = flags2name[flag]
    end
  end

  local round = band(3, rshift(csr,flags2bit['RN']))
  local rounding_flag = rounding_val[round]
  flags[rounding_flag] = flags2name[rounding_flag]
  return flags
end

function M.get_raw()
  return fpuLib.getcsr()
end

return M
