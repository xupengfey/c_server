
-- local pairs,os,math,next,table,cjson,print,type,printTable,tostring
--     = pairs,os,math,next,table,cjson,print,type,printTable,tostring
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mChar = require "logic.character"
local mObject = require "logic.object"
local mIndexdata = require "logic.indexdata"
local gData = require "template.gamedata".data
local mTeam = require "logic.team"
local mField =  require ("logic.battle.field")
local battleData=require("logic.battle.data")

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


function initCityWar( char )
	local b_citywar = {}

end


-- 战斗
function fightCell( sockId,cityId,cellId,hardLv )
	print("fightCell",sockId,cityId,cellId,hardLv)
	local char = mChar.getCharBySocket(sockId)
	if char.data.tili < tili_need then
		mSys.callClient(sockId, "onSysInfo", "体力不足")
		-- return
	end	
	if char.data.b_citywar == nil then
		initCityWar(char)
	end	

	local b_citywar = char.data.b_citywar

	-- if b_citywar[cityId][cellId][hardLv] == nil then
	-- 	return
	-- end	


	local creatureTpl = mIndexdata.data.citycell_creature[cityId][cellId][1]
	printTable(creatureTpl)

	local defTeam = mTeam.createCreatureTeam(creatureTpl)
	local atkTeam = mTeam.createCharTeam(char)

	local bf = mField.pvePointBattle(atkTeam, defTeam, onBattleComplete, {sockId=sockId})
	-- battleData.addBattle(bf)
	char.data.battleId = bf.id

	mSys.callClient(sockId, "onField", bf)

end

-- 历练
function exploreCell( sockId,cityId,cellId )
	local char = mChar.getCharBySocket(sockId)
	if char.data.tili < tili_need then
		mSys.callClient(sockId, "onSysInfo", "体力不足")
		return
	end
end

-- 攻略
function viewCellLog( sockId,cityId,cellId,hardLv )
		
end


function testCell( sockId, cell1,cell2 )
	local char = mChar.getCharBySocket(sockId)
	-- print("##############################")
	-- printTable(mIndexdata.data.citycell_creature)
	local creatureTpl = mIndexdata.data.citycell_creature[cell1.cityId][cell1.cellId][1]
	local atkTeam = mTeam.createCreatureTeam(creatureTpl)

	creatureTpl = mIndexdata.data.citycell_creature[cell2.cityId][cell2.cellId][1]
	local defTeam = mTeam.createCreatureTeam(creatureTpl)

	local bf = mField.pvePointBattle(atkTeam, defTeam, onBattleComplete, {sockId=sockId})
	-- battleData.addBattle(bf)
	char.data.battleId = bf.id
	mField.battleAuto(sockId)
	-- printTable(bf)
	mSys.callClient(sockId, "onField", bf)
end


function onBattleComplete(params)
	print("#####onBattleComplete########",params)
	local sockId = params.sockId
	local char = mChar.getCharBySocket(sockId) 
end











