-- local math,table=math,table

local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mChar = require "logic.character"
local mObject = require "logic.object"
local mIndexdata = require "logic.indexdata"
local cardType=require"logic.constants.CardType"
local mGameData = require "template.gamedata".data


module ("logic.card",package.seeall)

-- 卡牌 b_card 结构 id索引
-- id 一个玩家不同card的id唯一
	-- atk
	-- hp 
	-- tid 模板表id
	-- cardLv 等级
	--exp 

-- 卡组 b_card_group 结构 id索引
-- id 一个玩家不同卡组的id唯一1,2,3
	-- pos1 pos2...pos10 对应card的id
--usedGid 当前采用的卡组

function addCard(charId,tid,lv,atk,hp)
	local char = mChar.getCharById(charId)
	if char.data.b_card == nil then
		char.data.b_card = {}
	end	
	local card=createCard(charId,tid,lv,atk,hp)
	table.insert(char.data.b_card,card)
	mObject.set(char, "b_card", char.data.b_card)
end

function removeCard(cardId,sockId)
	local char = mChar.getCharBySockId(sockId)
	table.remove(char.data.b_card,cardId)
	mObject.set(char, "b_card", char.data.b_card)
	mSys.callClient(sockId, "onRemoveCard",cardId)
end

function createCard(charId,tid,lv,atk,hp)
	local char = mChar.getCharById(charId)
	local card={}
	card.id=getMaxCardId(char)+1
	card.atk=atk
	card.hp=hp
	card.cardLv=lv
	card.tid=tid
	card.exp=0
	return card
end

function getMaxCardId(char)
	local mId=0
	for k,v in pairs(char.data.b_card) do
		if v.id>mId then
			mId=v.id
		end
	end
	return mId
end

--升级
function  cardUpgrade( cardId,srcCardId,sockId )
	local char = mChar.getCharBySockId(sockId)
	local b_card = char.data.b_card
	if b_card[cardId]~=nil and b_card[srcCardId]~=nil then
		local tarCard=b_card[cardId]
		tarTemp=mTData["card"][tarCard.tid]
		local srcCard=b_card[srcCardId]
		srcTemp=mTData["card"][srcCardId.tid]
		if tarCard.lv==10 then
			return
		end
		local addExp=math.floor(cardType.CARD_EXP_TOUPGRADE[srcTemp.star][srcCard.lv]/2)+srcCard.exp
		local upgradeExp=cardType.CARD_EXP_TOUPGRADE[tarTemp.star][tarCard.lv+1]
		local price=cardType.CARD_UPGRADE_PRICE[tarTemp.star]*addExp
		if char.data.coin<price then
			return
		end
		tarCard.exp=tarCard.exp+addExp		
		while(tarCard.exp>upgradeExp) do
			tarCard.lv=tarCard.lv+1
			tarCard.exp=tarCard.exp-upgradeExp
			upgradeExp=cardType.CARD_EXP_TOUPGRADE[tarTemp.star][tarCard.lv+1]
		end
		mChar.updateCoin(char,-price)
		mObject.set(char,"b_card",b_card)
		mSys.callClient(sockId, "onCardUpgrade",tarCard,srcCardId)
	end
end

function sellCard(cardId,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_card = char.data.b_card
	if b_card[cardId]~=nil then
		local card=b_card[cardId]
		local temp=mTData["card"][card.tid]
		local price=(cardType.CARD_EXP_TOUPGRADE[temp.star][card.lv]+card.exp)*cardType.CARD_SELL_PRICE[temp.star]
		table.remove(b_card,cardId)
		mChar.updateCoin(char,price)
		mObject.set(char,"b_card",b_card)
		mSys.callClient(sockId, "onSellCard",cardId)
	end
end

--设置卡组
function updateGoupCard(gid,data,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_card_group = char.data.b_card_group
	if char.data.lv<cardType.CARD_GROUP_NUM_LV_LIMIT[gid] then
		return
	end
	if b_card_group[gid]==nil then
		b_card_group[gid]={}
	end
	if checkCardAvalible(data,charId)==false then
		return
	end
	for k=1,10 do
		if data["pos"..k]~=nil	then
			b_card_group[gid]["pos"..k]=data["pos"..k]
		end
	end
	mSys.callClient(sockId, "onUpdateGoupCard",b_card_group[gid])
end

function checkCardAvalible(data,charId) 
	local char = mChar.getCharBySockId(sockId)
	local cardNum=0
	for k=1,10 do
		if data["pos"..k]~=nil	then
			cardNum=cardNum+1
		end
	end
	if char.data.lv<cardType.CARD_NUM_LV_LIMIT[cardNum] then
		return false
	else
		return true
	end
end

--设置当前的卡组
function setUsedGid(gid,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_card_group = char.data.b_card_group
	b_card_group.usedGid=gid
	mSys.callClient(sockId, "onSetUsedGid",gid)
end

function getBattleCards(charId)
	local char = mChar.getCharById(charId)
	local b_card_group = char.data.b_card_group
	local group=b_card_group[b_card_group.usedGid]
	local cardList={}
	for k=1,10 do
		if group["pos"..k] ~=nil then
			local cardId=group["pos"..k]
			local card=char.data.b_card[cardId]
			table.insert(cardList,card)
		end
	end
	return cardList
end


function initCardGroup( char )
	local cardGroup = {usedGid = 1}
	local group = {}
	table.insert(cardGroup, group)
end