package.path = ";;../../Dropbox/cern/madStripped/mad/src/blackBoxTest/?.lua;"
local start = os.clock()
require"luaFile100kLines"
local stop = os.clock()
print("Total time =", stop-start)
