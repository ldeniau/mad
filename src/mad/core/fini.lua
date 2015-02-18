local M = { help = {}, test = {} }

M.help.self = [[
NAME
	mad.fini
DESCRIPTION
	
]]
-- metamethods ----------------------------------------------------------------
local mt = {}; setmetatable(M, mt)
local call
mt.__call = function (...)
	return call(...)
end
-- require --------------------------------------------------------------------

-- module ---------------------------------------------------------------------

call = function(_, options)
	if options.profiler then
		require"jit.p".stop()
	end
end

-- end ------------------------------------------------------------------------
return M
