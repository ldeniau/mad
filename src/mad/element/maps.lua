local M  = { help={}, test={} }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  mad.element.maps -- build MAD element dynamical maps

SYNOPSIS
  maps = require"mad.element.maps"

DESCRIPTION
  The module mad.element.maps provides the slice maps used to build MAD elements.

RETURN VALUES
  The list of supported maps.

SEE ALSO
  mad.element
]]

-- requires --------------------------------------------------------------------

local object = require"mad.object"
local utils = require"mad.utils"

-- locals ----------------------------------------------------------------------

local type, setmetatable = type, setmetatable
local rawget = rawget
local is_list, show_list = utils.is_list, utils.show_list

-- functions -------------------------------------------------------------------

local track_drift = function ()

end

-- test suite -----------------------------------------------------------------------

-- end -------------------------------------------------------------------------
return M
