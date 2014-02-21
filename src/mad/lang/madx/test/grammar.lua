local M = {}

function M:setUp()
    self.grammar = require "mad.lang.madx.grammar".grammar
    self.compile = require"lib.lpeg.re".compile
    self.defs = require"mad.lang.madx.defs".defs
end

function M:tearDown()
    self.grammar = nil
    self.compile = nil
    self.defs    = nil
end

-- end ----
return M

