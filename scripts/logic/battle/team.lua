local require,pairs,cloneTable,table,math,printTable,print = require,pairs,cloneTable,table,math,printTable,print
local mTData = require("template.gamedata").data
local battleType = require("logic.constants.BattleType")
module("logic.battle.team")

function cardInitData(card)
	card.buffHpMinus=0   --当hp小于0 ，buff会加hp时，扣除buff中hp的价值
	card.data={}
	card.data.buff={}
	card.data.buff.atk={}
	card.data.buff.hp={}
	card.data.buff.state={}
	card.data.buff.target={}
	card.data.buff.hpDebuff={}
	card.data.buff.skillBan={}  --禁用的技能
	card.data.buff.addSkill={}  --临时加的技能
end

function initCard(card)
	card.hpTotal=card.hp
	cardInitData(card)
end

function inintCardByDead(card)
	card.hp=card.hpTotal
	cardInitData(card)
end

----把一张卡片放到canditate
function addOneToCanditate(bf,team)
	if #team.cardList>0 then
		local rd=math.random(1,#team.cardList)
		local card=team.cardList[rd]
		card.roundNum=0   --从等待区开始的回合数
		card.battleCount=0 --战斗回合数
		card.isNew=true --新上场的卡牌
		table.insert(team.canditate,card)
		table.remove(team.cardList,rd)	
		
		local viewCard={}
		viewCard.id=card.id
		viewCard.tid=card.tid
		viewCard.tid=card.tid
		viewCard.teamId=card.teamId
		viewCard.atk=card.atk
		viewCard.hp=card.hp
		local teamId=team.hero.teamId
		if bf.enterBattleList[bf.roundNum]==nil then
			bf.enterBattleList[bf.roundNum]={}
		end
		if bf.enterBattleList[bf.roundNum][teamId]==nil then
			bf.enterBattleList[bf.roundNum][teamId]={}
		end
		table.insert(bf.enterBattleList[bf.roundNum][teamId], viewCard)
	end	
end

--增加在canditate卡片的回合数
function addCanditateRoundNum(team)
	for k,v in pairs(team.canditate) do
		v.roundNum=v.roundNum+1		
	end
	for k,v in pairs(team.cards) do
		v.battleCount=v.battleCount+1
	end
end

function putTempCardToBattle(team)
	for k,v in pairs(team.tempCards) do
		table.insert(team.cards,v)
		table.remove(team.tempCards,k)	
	end
end
--把卡片放到战斗区
function autoPutToBattle(team)
	for k,v in pairs(team.canditate) do
		local cardTmp= mTData["card"][v.tid]
		if v.roundNum>=cardTmp.cd then
			team.battleCardNum=team.battleCardNum+1
			table.insert(team.cards,v)
			table.remove(team.canditate,k)	
		end
	end
end

function initPlayerTeam(charData,teamId)
	local team = {}
	team.id = charData.id
	if charData.charName ~= nil then
		team.charName = charData.charName
	end
	team.capacity = charData.capacity
	team.status = battleType.TEAM_STATUS.READY	
	team.lv = charData.lv
	team.hero=charData.hero--cloneTable(charData.hero)
	team.hero.teamId=teamId
	team.hero.hpTotal=team.hero.hp
	--初始化英雄的法宝
	for k,v in pairs(team.hero.magicList) do
		v.triggerNum=0  --已触发次数
	end
	team.cemetery={}   --死亡区
	team.cardList=charData.cardList--cloneTable(charData.cardList)  --牌堆
	team.canditate={}   --守牌区
	team.cards={}       --战斗区卡牌
	team.tempCards={}   --临时玩家上下卡牌
	team.battleCardNum=0
	for k,v in pairs (team.cardList) do
		v.teamId=teamId
		initCard(v)		
	end	
	--addOneToCanditate(1,team)
	return team
end





