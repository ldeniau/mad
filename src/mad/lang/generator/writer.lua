local Writer = { }
Writer.__index = Writer

function Writer:new()
	return setmetatable({
		line	= 1,
		level  = 0,
		dent	= '	',
		margin = '',
		buffer = { },
	}, self)
end
function Writer:indent()
	self.level  = self.level + 1
	self.margin = string.rep(self.dent, self.level)
end
function Writer:undent()
	self.level  = self.level - 1
	self.margin = string.rep(self.dent, self.level)
end
function Writer:writeln()
	self.buffer[#self.buffer + 1] = "\n"..self.margin
	self.line = self.line + 1
end
function Writer:write(str)
	self.buffer[#self.buffer + 1] = str
end
function Writer:__tostring()
	return table.concat(self.buffer)
end

return Writer
