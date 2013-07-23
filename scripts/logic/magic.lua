 local pairs,os,math,next,table,cjson,print,type,printTable,tostring   = pairs,os,math,next,table,cjson,print,type,printTable,tostring
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mCache=require "logic.character"
local mChar = require "logic.character"
local magicType=require "logic.constants.MagicType"
local mObject = require "logic.object"
local mTData = require("template.gamedata").data
module ("logic.magic")

-- 法宝 b_magic 结构
-- id 一个玩家不同magic的id唯一
	-- iswear 1已经穿上 0未穿上
	-- position 位置  分为装备上的位置和没有穿上的位置
	-- lv 等级
	-- tid 模板表id
	-- exp 当前经验

--装备
function wearMagic(magicId,dstPos,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_magic = char.data.b_magic
	local magic2=checkPosIsEmpty(char.data.id,magicType.WEAR_STATUS.WEAR_ON,dstPos)
	if char.data.lv<magicType.MAGIC_NUM_LV_LIMIT[dstPos] then
		return
	end
	if b_magic[magicId]~=nil then
		if magic2~=nil then
			magic2.iswear=magicType.WEAR_STATUS.WEAR_OFF
			magic2.position=magic.position
		end
		local magic=b_magic[magicId]
		magic.iswear=magicType.WEAR_STATUS.WEAR_ON
		magic.position=dstPos
		mObject.set(char,"b_magic",b_magic)
		mSys.callClient(sockId, "onWearMagic",magicId,dstPos)
	end
end

--卸下
function removeMagic(poision,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_magic = char.data.b_magic
	if b_magic[magicId]~=nil then
		local magic=b_magic[magicId]
		magic.iswear=magicType.WEAR_STATUS.WEAR_OFF
		magic.position=getMimPositon(0,charId)
		mObject.set(char,"b_magic",b_magic)
		mSys.callClient(sockId, "onRemoveMagic",srcPos,magic.position)
	end
end

--移动位置
function magicMove(magicId,pos,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_magic = char.data.b_magic
	local magic2=checkPosIsEmpty(char.data.id,magicType.WEAR_STATUS.WEAR_ON,pos)
	if b_magic[magicId]~=nil then
		if magic2~=nil then
			magic2.position=magic.position
		end
		magic.position=pos
		mObject.set(char,"b_magic",b_magic)
		mSys.callClient(sockId, "onMoveMagic",magicId,pos)
	end
end

--升级
function magicUpgrade( magicId,srcMagicId,sockId )
	local char = mChar.getCharBySockId(sockId)
	local b_magic = char.data.b_magic
	if b_magic[magicId]~=nil and b_magic[srcMagicId]~=nil then
		local tarMagic=b_magic[magicId]
		tarTemp=mTData["magic"][tarMagic.tid]
		local srcMagic=b_magic[srcMagicId]
		srcTemp=mTData["magic"][srcMagic.tid]
		if tarMagic.lv==4 then
			return
		end
		local addExp=magicType.MAGIC_EXP_TOOTHER[srcTemp.star][srcMagic.lv]+srcMagic.exp
		local upgradeExp=magicType.MAGIC_EXP_TOUPGRADE[tarTemp.star][tarMagic.lv+1]
		local price=magicType.MAGIC_UPGRADE_PRICE[tarTemp.star]*addExp
		if char.data.coin<price then
			return
		end
		tarMagic.exp=tarMagic.exp+addExp		
		while(tarMagic.exp>upgradeExp) do
			tarMagic.lv=tarMagic.lv+1
			tarMagic.exp=tarMagic.exp-upgradeExp
			upgradeExp=magicType.MAGIC_EXP_TOUPGRADE[tarTemp.star][tarMagic.lv+1]
		end
		mChar.updateCoin(char,-price)
		mObject.set(char,"b_magic",b_magic)
		mSys.callClient(sockId, "onMagicUpgrade",tarMagic,srcMagicId)
	end
end

--得到最小位置
function getMimPositon(iswear,charId)
	local char = mChar.getCharById(charId)
	local b_magic = char.data.b_magic
	local posList={}
	for k,v in pairs(b_magic) do
		if v.iswear==iswear then
			posList[v.position]=true
		end
	end
	local pos=#posList+1
end

--增加一法宝
function addMagic(charId,lv,tid)
	local char = mChar.getCharById(charId)
	local magic=createMagic(charId,lv,tid)
	table.insert(char.data.b_magic,magic)
	mObject.set(char,"b_magic",b_magic)
end

function sellMagic(magicId,sockId)
	local char = mChar.getCharBySockId(sockId)
	local b_magic = char.data.b_magic
	if b_magic[magicId]~=nil then
		local magic=b_magic[magicId]
		local temp=mTData["magic"][magic.tid]
		local price=(magicType.MAGIC_EXP_TOUPGRADE[temp.star][magic.lv]+magic.exp)*magicType.MAGIC_SELL_PRICE[temp.star]
		table.remove(b_magic,magicId)
		mChar.updateCoin(char,price)
		mObject.set(char,"b_magic",b_magic)
		mSys.callClient(sockId, "onSellMagic",magicId)
	end
end

--构造法宝
function createMagic(charId,lv,tid)
	local char = mChar.getCharById(sockId)
	local b_magic = char.data.b_magic
	local magic={}
	magic.id=getMaxMagicId(charId)+1
	magic.iswear=magicType.WEAR_STATUS.WEAR_OFF
	magic.position=getMimPositon(0,charId)
	magic.lv=lv
	magic.tid=tid
	magic.exp=0
	return magic
end

function getMaxMagicId(charId)
	local mId=0
	for k,v in pairs(char.data.b_magic) do
		if v.id>mId then
			mId=v.id
		end
	end
	return mId
end

function checkPosIsEmpty(charId,wearType,pos)
	local char = mChar.getCharById(charId)
	local b_magic = char.data.b_magic
	local magic
	for k,v in pairs(b_magic) do
		if v.iswear==wearType and v.position==pos then
			magic=v
		end
	end
	return magic
end
	
--得到装备的法宝列表
function getMagicUsedList(charId)
	local char = mChar.getCharById(sockId)
	local b_magic = char.data.b_magic
	local tb={}
	for k,v in pairs(b_magic) do
		if v.iswear==magicType.WEAR_STATUS.WEAR_ON then
			table.insert(tb,v)
		end
	end
	return tb
end





