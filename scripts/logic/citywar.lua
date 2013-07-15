
-- local pairs,os,math,next,table,cjson,print,type,printTable,tostring
--     = pairs,os,math,next,table,cjson,print,type,printTable,tostring
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mChar = require "logic.character"
local mObject = require ""logic.object""
module ("logic.citywar",package.seeall)

-- b_citywar
-- current
-- 	 {cityId,cellId,hardLv}
-- log
--   {cityId,{cellId,{hardLv,attacked}}}

-- 攻略 全局 t_citywar_fight_log


-- tpl tpl_city tpl_city_cell

local cell_status = 
{
	opened = 0,
	attacked = 1,
}

local tili_need = 2

-- 战斗
function fightCell( sockId,cityId,cellId,hardLv )
	local char = mChar.getCharBySockId(sockId)
	if char.data.tili < tili_need then
		mSys.callClient(sockId, "onSysInfo", "体力不足")
		return
	end	

	local b_citywar = char.data.b_citywar

	if b_citywar[cityId][cellId][hardLv] == nil then
		return
	end	


end

-- 历练
function exploreCell( sockId,cityId,cellId )
	local char = mChar.getCharBySockId(sockId)
	if char.data.tili < tili_need then
		mSys.callClient(sockId, "onSysInfo", "体力不足")
		return
	end
end

-- 攻略
function viewCellLog( sockId,cityId,cellId,hardLv )
		
end






