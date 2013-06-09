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
	local num = math.random(10000)
	for i=1,num do
		table.insert(data, "adfaklfjakdf;asdkf;akdfal;kdf';")
	end	
	mSys.callNc(1, "funcName", data)
	mTimer.setTimeOut(send,math.random(0,200))
end


function test_sendData( ... )
	mSys.connect(ip, listenPort)
	mTimer.setTimeOut(send,100)
end


test_sendData()






