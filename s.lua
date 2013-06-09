package.path = "scripts/?.lua;"
print("load s.lua")
require "system.core"
local mSys = require "system.sys"
local mTimer = require "system.timer"


local ip = "192.168.0.63"
local listenPort = "8000"


mSys.listen(listenPort)




function onPerfTest( sockId,... )
	print("onPerfTest",sockId,...)
	mSys.callClient(sockId, "onPerfTest", ...)
end
mSys.regClientFunc("perfTest", onPerfTest)