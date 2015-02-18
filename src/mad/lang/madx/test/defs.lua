local M = {}

function M:setUp()
    self.defs = require"mad.lang.madx.defs".defs
end

function M:tearDown()
end

function M:error( ut )
    ut:fails(self.defs.error,[[a = 1;]], 0)
end


return M
