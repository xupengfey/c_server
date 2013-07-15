
-- local pairs,os,math,next,table,cjson,print,type,printTable,tostring
--     = pairs,os,math,next,table,cjson,print,type,printTable,tostring
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mChar = require "logic.character"
local mObject = require ""logic.object""
module ("logic.reportcache",package.seeall)

local INDEX = os.time()
local MAX_REPORT_CNT = 1000

local cache = {
	cnt = 0,
	list = {},
}




function getReport( key )
	return cache.list[key]
end


function addReport( data )
	INDEX = INDEX + 1
	cache.cnt = cache.cnt + 1
	cache.list[INDEX] = data
end

function deleteReport( key )
	if cache.list[key] ~= nil then
		cache.list[key] = nil
		cache.cnt = cache.cnt - 1
	end	
end
