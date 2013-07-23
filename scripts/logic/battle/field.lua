local type,assert,math,table,pairs,print,tonumber,cloneTable,package,require,printTable,splitWithTrim,os = type,assert,math,table,pairs,print,tonumber,cloneTable,package,require,printTable,splitWithTrim,os
local C_ClientCall = C_ClientCall
local mTeam = require("logic.battle.team")
local battleType = require("logic.constants.BattleType")
local battleMgr=require("logic.battle.battle")
local battleData=require("logic.battle.data")
local mChar = require "logic.character"
local mSys = require "system.sys"
module ("logic.battle.field")

local MAX_COUNT=30

function createBattleField(id, mode, t1, t2)
	local bf = {}
	bf.id = id
	bf.mode = mode
	bf.creatTime = os.time()
	bf.enterBattleList={}   --是每个回个从牌堆取出来的卡牌列表
	bf.resultList={}	    --播放列表
	bf.playList = {}
	bf.roundNum = 1
	bf.team1 = t1
	bf.team2 = t2
	bf.status=battleType.FIELD_STATUS.INIT
	bf.winnerId=0
	return bf
end

--
function pvePointBattle(attackData, defendData, callback, params)
	local team1 = mTeam.initPlayerTeam(attackData,1)
	local team2 = mTeam.initPlayerTeam(defendData,2)
	-- if attackData.battle~=nil and attackData.battle.id~=nil then
		-- return
	-- end
	-- local fid=#battleData.battleFieldList+1
	local field=createBattleField(fid, battleType.BATTLE_TYPE.point, team1, team2)
	
	mTeam.addOneToCanditate(field,field.team1)	
	mTeam.addOneToCanditate(field,field.team2)	


	battleData.addBattle(field, callback, params)
	-- if flag~=nil and flag==1 then
		-- battleAuto(field)
	-- else
		-- mTeam.addOneToCanditate(bf.team1)		
		-- attackData.battle={}
		-- attackData.battle.id=fid		
		-- return field
	-- end
	return field
end

function addCardToBattle(index,sockId)
	local char = mChar.getCharBySocket(sockId)
	local bf=battleData.getBattleBf(char.data.battleId)
	local card=bf.team1.canditate[index]
	if card~=nil then
		card.candInd=index
		table.insert(bf.team1.tempCards,card)
		table.remove(bf.team1.canditate,index)
		return true
	else
		return false
	end
	mSys.callClient(sockId, "onAddCardToBattle",index)
end

function removeCardFromBattle(cardId,sockId)
	local char = mChar.getCharBySocket(sockId)
	local bf=battleData.getBattleBf(char.data.battleId)
	local index=-1
	for k,v in pairs(bf.team1.tempCards) do
		if v.id==cardId then
			index=k
		end
	end
	if index>0 then
		local card=bf.team1.tempCards[index]
		table.insert(bf.team1.canditate,card,card.candInd)
		table.remove(bf.team1.tempCards,index)
		return true
	else
		return false
	end
	mSys.callClient(sockId, "onRemoveCardFromBattle",cardId)
end

function battleOneRoundInternal(bf)
	--把temp 放到战斗区
	mTeam.putTempCardToBattle(bf.team1)
	mTeam.putTempCardToBattle(bf.team2)
	
	battleMgr.battleStart(bf)

	if bf.status == battleType.FIELD_STATUS.END then
		return
	end	
	
	bf.status=battleType.FIELD_STATUS.BATTLEING
	bf.roundNum = bf.roundNum + 1
	if bf.roundNum> MAX_COUNT then
		battleMgr.battleEnd(bf)
	end
	--增加在canditate卡片的回合数
	mTeam.addCanditateRoundNum(bf.team1)
	mTeam.addCanditateRoundNum(bf.team2)
	
	--把一张卡片放到canditate
	mTeam.addOneToCanditate(bf,bf.team1)
	mTeam.addOneToCanditate(bf,bf.team2)
	
	mTeam.autoPutToBattle(bf.team2) --把卡片放到战斗区
end
function battleOneRound(sockId)
	local char = mChar.getCharBySocket(sockId)
	local bf=battleData.getBattleBf(char.data.battleId)
	battleOneRoundInternal(bf)
	local bfView={}
	bfView.roundNum=bf.roundNum
	bfView.enterBattleList=bf.enterBattleList[bf.roundNum-1]
	bfView.playList=bf.playList[bf.roundNum-1]
	bfView.status=bf.status
	bfView.winnerId=bf.winnerId
	mSys.callClient(sockId, "onBattleOneRound",bfView)
end

function battleAuto(sockId)
	local char = mChar.getCharBySocket(sockId)
	local bf=battleData.getBattleBf(char.data.battleId)
	while true do
		
		--把卡片放到战斗区
		mTeam.autoPutToBattle(bf.team1)
		
	
		if bf.status~=battleType.FIELD_STATUS.END then
			battleOneRoundInternal(bf)
		else	
			break
		end
		
		if bf.roundNum> MAX_COUNT then
			battleMgr.battleEnd(bf)
			break
		end	
		if bf.status==battleType.FIELD_STATUS.END then
			break
		end	
	end
	local bfView={}
	bfView.enterBattleList=bf.enterBattleList
	bfView.playList=bf.playList
	bfView.status=bf.status
	bfView.winnerId=bf.winnerId
	mSys.callClient(sockId, "onBattleAuto",bfView)
	--return bf
end

