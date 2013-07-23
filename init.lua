package.path = "./?.lua;scripts/?.lua;"
print("load init.lua")
require "system.core"
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mIndexData = require "logic.indexdata"



math.randomseed(os.time())

-- LISTENPORT = 8000
-- DB_IP = "192.168.99.200"
-- DB_USER = "root"
-- DB_PASSWD = "123456"
-- DB_NAME = ""
-- DB_PORT = 3306
-- dbConnect( server,user,pass,database,port )
local ret = mSys.dbConnect( mConfig.DB_IP,mConfig.DB_USER,mConfig.DB_PASSWD,
	mConfig.DB_NAME,mConfig.DB_PORT )



assert(ret == 0, "dbConnect failed")


print(type(mSys.dbConnect))
printTable(mConfig)

require "logic.handler"


mSys.regNcFunc("testnc", function (  )
	return
end)

-- local ip = "127.0.0.1"
local listenPort = "8000"

mSys.listen(listenPort)


-- function send( ... )
-- 	print("send data")
-- 	local data = {}
-- 	local num = math.random(100)
-- 	-- local num = 900000
-- 	for i=1,num do
-- 		table.insert(data, "adfaklfjakdf;asdkf;akdfal;kdf';")
-- 	end	
-- 	mSys.callNc(1, "perfTest", data)
-- 	mTimer.setTimeOut(send,math.random(0,100))
-- end


-- function test_sendData( ... )
-- 	mSys.connect(ip, listenPort)
-- 	mTimer.setTimeOut(send,100)
-- end


-- test_sendData()






