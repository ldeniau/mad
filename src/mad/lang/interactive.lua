local M  = { help = {}, test = {}, _author = "MV", _year = 2013 }

-- MAD -------------------------------------------------------------------------

M.help.self = [[
NAME
  interactive

SYNOPSIS
  local interactive = require "mad.lang.interactive"

DESCRIPTION
  

RETURN VALUES
  

SEE ALSO
  None
]]

-- require ---------------------------------------------------------------------
local util = require"mad.lang.util"
local env = require"mad.lang.environment"
local run = require"run"

-- modules ---------------------------------------------------------------------

local function loadstring2(str, chunkname)
  local compiledcode, errormsg = loadstring(str, chunkname)
  local patt = "Unexpected"
  if errormsg then
    if string.find(errormsg, patt) then
      return nil, nil, "incomplete"
    else
      return nil, errormsg, nil
    end
  end
  return compiledcode, nil, nil
end

local function exitInteractive(ret)
	env.popEnvironment()
	return 0, ret
end


M.interactive = function (  )
	local newEnv = env.newEnvironment(env.environment(), { position = 1, fileName = "stdin" })
	env.pushEnvironment(newEnv)
	local self = {}
	self.iprefix = ""
	self.icompiled = nil
	self.ierrormsg = nil
	self.ichunkname = "istdin"
  self.iincomplete = nil
  self.patt = ": unexpected symbol near '<eof>'$"
  
  function self:getCode(icode)
		local iline = io.read()
		if not iline then
			return nil
		end
		if not icode then
			if string.sub(iline, 1, 1) == "=" then
				self.iprefix = "="
				icode = "return " .. string.sub(iline, 2)
			else
				self.iprefix = ""
				icode = iline
			end
		else
			icode = icode .. "\n" .. iline
		end
		return icode
	end
  
  while true do
  	io.write("\t> ")
  	local icode, done
  	icode = self:getCode(icode)
  	while icode do
  		local nEnv = env.newEnvironment( env.environment(), { inputStream = icode } )
    	self.icompiled, self.ierrormsg, self.iincomplete = loadstring2(run.createSource(nEnv), "=interactive")
    	if not self.iincomplete then
		  	if self.ierrormsg then
		  		print(self.ierrormsg)
				else
		  		local ret = run.runLuaCode(self.icompiled)
		  	end
				done = true
				break
			else
				io.write("\t>>")
				icode = self:getCode(icode)
			end
  	end
  	if not done then
  		exitInteractive()
  	end
  end
	return exitInteractive(true)
end






-- end ------------------------------------------------------------------------
return M
