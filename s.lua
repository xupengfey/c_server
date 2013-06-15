package.path = "scripts/?.lua;"
print("load s.lua")
require "system.core"
local mSys = require "system.sys"
local mTimer = require "system.timer"


local ip = "127.0.0.1"
local listenPort = "8000"


mSys.listen(listenPort)




function onPerfTest( sockId,... )
	print("onPerfTest",sockId,...)
	printTable({sockId,...})
	mSys.callClient(sockId, "onPerfTest", ...)
end
mSys.regClientFunc("perfTest", onPerfTest)

-- function send( ... )
	-- print("send data\n")
	-- local data = {}
	-- local num = math.random(100)
	-- for i=1,num do
		-- table.insert(data, "adfaklfjakdf;asdkf;akdfal;kdf';")
	-- end	
	-- mSys.callNc(1, "perfTest", data)
	-- mTimer.setTimeOut(send,math.random(0,100))
-- end


-- function test_sendData( ... )
	-- mSys.connect(ip, listenPort)
	-- mTimer.setTimeOut(send,100)
-- end


-- test_sendData()