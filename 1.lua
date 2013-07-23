local mSys = require "system.sys"
local mCitywar = require "logic.citywar"
local mCard = require "logic.card"
local mMagic = require "logic.magic"
local gData = require "template.gamedata".data
-- mSys.callClient(1, "adfadf", "dsafaaaaaaaaaaaaaaaaaaa")

-- mCitywar.testCell(1,{cityId=1,cellId=1},{cityId=1,cellId=1})

-- mCitywar.abc({cityId=1,cellId=1},{cityId=1,cellId=1})
local mChar = require "logic.character"
local mLogin = require "logic.login"
-- mLogin.login(1,{accName="x1"})
local char = mChar.getCharByAccName("x1")

-- local tid = 1
-- local cardTmp = gData.card[tid]

-- mCard.addCard(char.data.id,tid,0,cardTmp.atk0,cardTmp.hp0)


-- mCitywar.testCell(char.sockId,{cityId=1,cellId=1},{cityId=1,cellId=1})
-- function broadCastToSockList( sockList,  funcName, ...)
-- 	return C_broadcast(sockList, 1, {funcName,...})
-- end

-- function broadcastToAll( funcName, ... )
-- 	return C_broadcastall(1, {funcName,...})
-- end
local sockList = {}
sockList[char.sockId] = char.sockId
mSys.broadCastToSockList(sockList, "broadCastToSockList", "abc")

mSys.broadcastToAll("broadcastToAll", "abc")
-- printTable(char)

-- mSys.callClient(char.sockId, "testfunc", "abc", "111", {})


-- mLogin.login(1,{accName="x1"})



