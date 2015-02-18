local M = { help = {}, test = {} }
M.__index = M

function M:new()
    return setmetatable({
        line    = 1,
        level  = 0,
        dent    = '    ',
        margin = '',
        buffer = { },
    }, self)
end
function M:indent()
    self.level  = self.level + 1
    self.margin = string.rep(self.dent, self.level)
end
function M:undent()
    self.level  = self.level - 1
    self.margin = string.rep(self.dent, self.level)
end
function M:writeln()
    self.buffer[#self.buffer + 1] = "\n"..self.margin
    self.line = self.line + 1
end
function M:write(str)
    self.buffer[#self.buffer + 1] = str
end
function M:__tostring()
    return table.concat(self.buffer)
end

-- test -----------------------------------------------------------------------
function M.test:setUp()
    self.writer = M:new()
end

function M.test:tearDown()
    self.writer = nil
end

function M.test:new(ut)
    local new = M:new()
    ut:equals(new.line, 1)
    ut:equals(new.level, 0)
    ut:equals(new.dent, " ")
    ut:equals(new.margin, '')
    ut:equals(new.buffer, {})
end

function M.test:indent(ut)
end

function M.test:undent(ut)
end

function M.test:writeln(ut)
end

function M.test:write(ut)
end

function M.test:__tostring(ut)
end

return M
