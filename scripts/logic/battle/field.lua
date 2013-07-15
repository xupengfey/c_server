local type,assert,math,table,pairs,print,tonumber,cloneTable,package,require,printTable,splitWithTrim,os = type,assert,math,table,pairs,print,tonumber,cloneTable,package,require,printTable,splitWithTrim,os
local C_ClientCall = C_ClientCall
local mTeam = require("logic.battle.team")
local battleType = require("logic.constants.BattleType")
local battleMgr=require("logic.battle.battle")
local battleData=require("logic.battle.data")
module ("logic.battle.field")

local MAX_COUNT=30

function createBattleField(id, mode, t1, t2)
	local bf = {}
	bf.id = id
	bf.mode = mode
	bf.creatTime = os.time()
	bf.resultList={}	
	bf.playList = {}
	bf.roundNum = 1
	bf.team1 = t1
	bf.team2 = t2
	bf.status=battleType.FIELD_STATUS.INIT
	return bf
end

--flag=1 自动战斗
function pvePointBattle(attackData, defendData,flag)
	local team1 = mTeam.initPlayerTeam(attackData,1)
	local team2 = mTeam.initPlayerTeam(defendData,2)
	if attackData.battle~=nil and attackData.battle.id~=nil then
		return
	end
	local fid=#battleData.battleFieldList+1
	local field=createBattleField(fid, battleType.BATTLE_TYPE.point, team1, team2)
	if flag~=nil and flag==1 then
		battleAuto(field)
		return field
	else
		attackData.battle={}
		attackData.battle.id=fid		
		return field
	end
end

function addCardToBattle(bf,index)
	local card=bf.team1.canditate[index]
	if card~=nil then
		card.candInd=index
		table.insert(bf.team1.tempCards,card)
		table.remove(bf.team1.canditate,index)
		return true
	else
		return false
	end
end

function removeCardFromBattle(bf,cardId)
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
end

function battleOneRound(bf)
	battleMgr.battleStart(bf)
	
	bf.status=battleType.FIELD_STATUS.BATTLEING
	bf.roundNum = bf.roundNum + 1
	if bf.roundNum> MAX_COUNT then
		battleMgr.battleEnd(bf)
	end
	--把一张卡片放到canditate
	mTeam.addOneToCanditate(bf.team1)
	mTeam.addOneToCanditate(bf.team2)
	--增加在canditate卡片的回合数
	mTeam.addCanditateRoundNum(bf.team1)
	mTeam.addCanditateRoundNum(bf.team2)
	
	mTeam.autoPutToBattle(bf.team2) --把卡片放到战斗区
end

function battleAuto(bf)
	while true do
		
		--把卡片放到战斗区
		mTeam.autoPutToBattle(bf.team1)
		
	
		if bf.status~=battleType.FIELD_STATUS.END then
			battleOneRound(bf)
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
	return bf
end

