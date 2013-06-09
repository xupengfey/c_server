package.path = "scripts/?.lua;"
print("load test.lua")
require "system.core"
local mSys = require "system.sys"
local mTimer = require "system.timer"


local ip = "127.0.0.1"
local listenPort = "8000"



function send( ... )
	print("send data")
	local data = {}
	local num = math.random(100)
	-- local num = 900000
	for i=1,num do
		table.insert(data, "adfaklfjakdf;asdkf;akdfal;kdf';")
	end	
	mSys.callNc(1, "perfTest", data)
	mTimer.setTimeOut(send,math.random(0,100))
end


function test_sendData( ... )
	mSys.connect(ip, listenPort)
	mTimer.setTimeOut(send,100)
end


test_sendData()






