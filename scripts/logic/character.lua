local pairs,os,math,next,table,cjson
	= pairs,os,math,next,table,cjson
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mObject = require "logic.object"
module ("logic.character",package.seeall)

onlineNum = 0
sockIdToChar = {}
idToChar = {}
accNameToChar = {}
charNameToChar = {}


DIRTY_INTERVAL = 5 * 60

function getCharBySocket( sockId )
	return sockIdToChar[sockId]
end

function getCharById( id )
	return idToChar[id]
end

function getCharByAccName( accName )
	return accNameToChar[accName]
end

function getCharByCharName( charName )
	return charNameToChar[charName]
end

function loginData( char )
	char.dirty = {}
	char.writeTime = os.time() + math.random(DIRTY_INTERVAL)
	sockIdToChar[char.sockId] = char
	idToChar[char.data.id] = char
	accNameToChar[char.data.accName] = char
	charNameToChar[char.data.charName] = char
	onlineNum = onlineNum + 1
end

function logoutData( char )
	sockIdToChar[char.sockId] = nil
	idToChar[char.data.id] = nil
	accNameToChar[char.data.accName] = nil
	charNameToChar[char.data.charName] = nil
	onlineNum = onlineNum - 1
	writeDirty(char)
end

--¸üÐÂÍ­±Ò
function updateCoin(char,num)
	char.coin=char.coin+num
	mObject.set(char,"coin",char.coin)
end

function timerHandler( ... )
	local now = os.time()
	for _,char in pairs(sockIdToChar) do
		if now >= char.writeTime then
			char.writeTime = now + DIRTY_INTERVAL
			writeDirty( char )
		end	
	end
end

function writeDirty( char )
	print("writeDirty...")
	if next(char.dirty) ~= nil then
		local sql = "update t_character set key=value where id=char.data.id"
		local tmps = {}
		for key,_ in pairs(char.dirty) do
			if type(char.data[key]) == type(0) then
				table.insert(tmps, key.."="..char.data[key])
			elseif type(char.data[key]) == type("") then
				table.insert(tmps, key.."='"..char.data[key].."'")
			else
				table.insert(tmps, key.."='"..mSys.escapedStr(cjson.encode(char.data[key])).."'")
			end	
		end	
		char.dirty = {}
		local sql = "update t_character set "..table.concat(tmps, ",").." where id="..char.data.id
		mSys.dbQuery(sql, function () end)
	end	
end

function initTimer( ... )
	mTimer.setInterval(timerHandler, 1000*60)
end



