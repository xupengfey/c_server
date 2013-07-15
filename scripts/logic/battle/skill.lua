local assert,math,print,pairs,table,math,tonumber,printTable = assert,math,print,pairs,table,math,tonumber,printTable

local mView = require ("logic.battle.view")
local battleType = require ("logic.constants.BattleType")
local cardMgr=require "logic.battle.cardMgr"
local mSelect =require "logic.battle.select"
local mTData = require("template.gamedata").data
module ("logic.battle.skill")

activeSkills = {}

--根据技能等级添加攻击比例 roundNum=-1不限制回合
function addAtkBuffBySkillLv(self,atkAdd,roundNum,skillTid,skillLv)
	local buff={}
	buff.id=#self.data.buff.atk+1
	buff.roundNum=roundNum
	buff.atkAdd=atkAdd
	buff.skillTid=skillTid
	buff.skillLv=skillLv
	table.insert(self.data.buff.atk,buff)
	return buff
end

--根据技能等级添加血量比例
function addHpBuffBySkillLv(self,hpAdd,roundNum,skillTid,skillLv)
	local buff={}
	buff.id=#self.data.buff.hp+1
	buff.roundNum=roundNum
	buff.hpAdd=hpAdd
	buff.skillTid=skillTid
	buff.skillLv=skillLv
	table.insert(self.data.buff.hp,buff)
	return buff
end

--状态buff
function addStateBuffBySkillLv(self,stateName,roundNum,skillTid,skillLv,para)
	local buff={}
	buff.id=#self.data.buff.state+1
	buff.roundNum=roundNum
	buff.skillTid=skillTid
	buff.skillLv=skillLv
	if para~=nil then
		buff.para=para
	end
	self.data.buff.state[stateName]=buff		
	return buff
end


--debuff
function addHpDeBuffBySkillLv(self,hpAdd,roundNum,skillTid,skillLv)
	local buff={}
	buff.id=#self.data.buff.hpDebuff+1
	buff.roundNum=roundNum
	buff.hpAdd=hpAdd
	buff.skillTid=skillTid
	buff.skillLv=skillLv
	table.insert(self.data.buff.hpDebuff,buff)
	return buff
end


--技能 禁用 
function addSkillBan(self,skillIndex,roundNum)
	if self.data.buff.skillBan[skillIndex]==nil then
		self.data.buff.skillBan[skillIndex]=roundNum
	end
end

--添加临时技能
function addSkillBuff(self,roundNum,skillTid,para)
	local buff={}
	buff.id=#self.data.buff.addSkill+1
	buff.roundNum=roundNum
	buff.skillTid=skillTid
	buff.para=para
	table.insert(self.data.buff.addSkill,buff)
	return buff
end


-- function addAtkDeBuffBySkillLv(self,atkAdd,roundNum,skillTid,skillLv)
	-- local buff={}
	-- buff.id=#self.data.buff.AtkDebuff
	-- buff.roundNum=roundNum
	-- buff.atkAdd=atkAdd
	-- buff.skillTid=skillTid
	-- buff.skillLv=skillLv
	-- table.insert(self.data.buff.AtkDebuff,buff)
	-- return buff
-- end

function checkSkilledBuff(buffList,skillTid)
	for k,v in pairs(buffList) do
		if v.skillTId==skillTid then
			return v
		end
	end
	return nil
end

function checkBuffBySkillLv(buffList,skillTid,skillLv)
	for k,v in pairs(buffList) do
		if v.skillTId==skillTid and v.skillLv==skillLv then
			return v
		end
	end
	return nil
end


function getSkillLv(self,skillIndex)
	return mTData["card"][self.tid]["skill"..skillIndex.."Lv"]
end

function getPercentParaAdd(self,skillTid,skillIndex)
	local skillLv=getSkillLv(self,skillIndex)
	return math.floor(cardMgr.getCardAtk(self) *tonumber(mTData["skill"][skillTid]["para"..skillLv])/100)
end

function getAbsParaAdd(self,skillTid,skillIndex)
	local skillLv=getSkillLv(self,skillIndex)
	return tonumber(mTData["skill"][skillTid]["para"..skillLv])
end
--金克木
activeSkills[1] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if mTData["card"][target.tid].kind==2 then
			local atkAdd=getPercentParaAdd(self,1,skillIndex)
			mView.magicAttackCmd(bf,self,target,1)
			mView.atkChangeOnceCmd(bf, self, atkAdd)
			addAtkBuffBySkillLv(self,atkAdd,1,1,getSkillLv(self,skillIndex))
		end
	end	
end

--木克土
activeSkills[2] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if mTData["card"][target.tid].kind==5 then
			local atkAdd=getPercentParaAdd(self,2,skillIndex)
			mView.magicAttackCmd(bf,self,target,2)
			mView.atkChangeOnceCmd(bf, self, atkAdd)
			addAtkBuffBySkillLv(self,atkAdd,1,2,getSkillLv(self,skillIndex))
		end
	end	
end

--土克水
activeSkills[3] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if mTData["card"][target.tid].kind==3 then
			local atkAdd=getPercentParaAdd(self,3,skillIndex)
			mView.magicAttackCmd(bf,self,target,3)
			mView.atkChangeOnceCmd(bf, self, atkAdd)
			addAtkBuffBySkillLv(self,atkAdd,1,3,getSkillLv(self,skillIndex))
		end
	end	
end

--水克火
activeSkills[4] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if mTData["card"][target.tid].kind==4 then
			local atkAdd=getPercentParaAdd(self,4,skillIndex)
			mView.magicAttackCmd(bf,self,target,4)
			mView.atkChangeOnceCmd(bf, self, atkAdd)
			addAtkBuffBySkillLv(self,atkAdd,1,4,getSkillLv(self,skillIndex))
		end
	end	
end

--火克金
activeSkills[5] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if mTData["card"][target.tid].kind==1 then
			local atkAdd=getPercentParaAdd(self,5,skillIndex)
			mView.magicAttackCmd(bf,self,target,5)
			mView.atkChangeOnceCmd(bf, self, atkAdd)
			addAtkBuffBySkillLv(self,atkAdd,1,5,getSkillLv(self,skillIndex))
		end
	end	
end

--金之本源
activeSkills[6] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,1)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,6)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local atkAdd=getAbsParaAdd(self,6,skillIndex)
			local buff=addAtkBuffBySkillLv(target,atkAdd,-1,6,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="atk"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.atkChangeCmd(bf, target, atkAdd)
		end	
	end	
	
end

activeSkills[7] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,2)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,7)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local atkAdd=getAbsParaAdd(self,7,skillIndex)
			local buff=addAtkBuffBySkillLv(target,atkAdd,-1,7,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="atk"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.atkChangeCmd(bf, target, atkAdd)
		end	
	end	
	
end

activeSkills[8] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,3)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,8)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local atkAdd=getAbsParaAdd(self,8,skillIndex)
			local buff=addAtkBuffBySkillLv(target,atkAdd,-1,8,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="atk"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.atkChangeCmd(bf, target, atkAdd)
		end	
	end	
	
end

activeSkills[9] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,4)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,9)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local atkAdd=getAbsParaAdd(self,9,skillIndex)
			local buff=addAtkBuffBySkillLv(target,atkAdd,-1,9,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="atk"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.atkChangeCmd(bf, target, atkAdd)
		end	
	end	
	
end

activeSkills[10] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,5)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,10)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local atkAdd=getAbsParaAdd(self,10,skillIndex)
			local buff=addAtkBuffBySkillLv(target,atkAdd,-1,10,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="atk"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.atkChangeCmd(bf, target, atkAdd)
		end	
	end	
	
end

--金之守护
activeSkills[11] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,1)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,11)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local hpAdd=getAbsParaAdd(self,11,skillIndex)
			local buff=addHpBuffBySkillLv(target,hpAdd,-1,11,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="hp"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			mView.hpChangeCmd(bf, target, hpAdd)
		end	
	end	
	
end

activeSkills[12] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,2)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,12)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local hpAdd=getAbsParaAdd(self,12,skillIndex)
			local buff=addHpBuffBySkillLv(target,hpAdd,-1,12,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="hp"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			mView.hpChangeCmd(bf, target, hpAdd)
		end	
	end	
	
end

activeSkills[13] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,3)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,13)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local hpAdd=getAbsParaAdd(self,13,skillIndex)
			local buff=addHpBuffBySkillLv(target,hpAdd,-1,13,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="hp"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			mView.hpChangeCmd(bf, target, hpAdd)
		end	
	end	
	
end

activeSkills[14] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,4)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,14)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local hpAdd=getAbsParaAdd(self,14,skillIndex)
			local buff=addHpBuffBySkillLv(target,hpAdd,-1,14,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="hp"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.hpChangeCmd(bf, target, hpAdd)
		end	
	end	
	
end

activeSkills[15] = function (bf, self,skillIndex)
	local targetList=mSelect.selectKindExpectOne(bf,self,5)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,15)
	end	
	for k,target in pairs(targetList) do
		if self.data.buff.target[skillIndex]==nil then
			self.data.buff.target[skillIndex]={}
		end
		if self.data.buff.target[skillIndex][target.id]==nil then
			local hpAdd=getAbsParaAdd(self,15,skillIndex)
			local buff=addHpBuffBySkillLv(target,hpAdd,-1,15,getSkillLv(self,skillIndex))
			self.data.buff.target[skillIndex][target.id]={}
			self.data.buff.target[skillIndex][target.id]["buffName"]="hp"
			self.data.buff.target[skillIndex][target.id]["buffId"]=buff.id
			
			mView.hpChangeCmd(bf, target, hpAdd)
		end	
	end	
	
end


--暴击
activeSkills[16] = function (bf, self,skillIndex)
	if math.random(1,100)<=50 then
		local atkAdd=getPercentParaAdd(self,16,skillIndex)
		mView.magicAttackCmd(bf,self,self,16)
		mView.atkChangeOnceCmd(bf, self, atkAdd)
		addAtkBuffBySkillLv(self,atkAdd,1,16,getSkillLv(self,skillIndex))
	end	
end

--气场
activeSkills[17] = function (bf, self,skillIndex)
	--if self.isNew==true then
	local atkAdd=getAbsParaAdd(self,17,skillIndex)
	mView.magicAttackCmd(bf,self,self,17)
	mView.atkChangeOnceCmd(bf, self, atkAdd)
	addAtkBuffBySkillLv(self,atkAdd,1,17,getSkillLv(self,skillIndex))
	--end	
end

--activeSkills[18] = function (bf, self,skillIndex)
--	local atkAdd=skill.getAbsParaAdd(self,18,skillIndex)
--	addAtkBuffBySkillLv(self,atkAdd,-1,18,skill.getSkillLv(self,skillIndex))
--	mView.magicAttackCmd(bf,self,self,18)
--	mView.atkChangeOnceCmd(bf, self, atkAdd)
--end

--嗜血
--activeSkills[19] = function (bf, self,skillIndex)
--	local num=skill.getAbsParaAdd(self,19,skillIndex)
--	local skillLv=getSkillLv(self,skillIndex)
--	mView.magicAttackCmd(bf,self,self,19)
--	mView.addStateBuffCmd(bf,self,battleType.BATTLE_STATE.BLOOD_SUCK,-1)
--	addStateBuffBySkillLv(self,battleType.BATTLE_STATE.BLOOD_SUCK,-1,19,skillLv,num)
--	
--end

--透支
activeSkills[23] = function (bf, self,skillIndex)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][23]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	local atkAdd= cardMgr.getCardAtk(self) *tonumber(paraList[2])
	
	mView.magicAttackCmd(bf,self,self,19)
	
	if self.hp>minusHp then
		cardMgr.doMinusHpMagic(bf,target,minusHp)			
		addAtkBuffBySkillLv(self,atkAdd,1,23,skillLv)	
		
		mView.atkChangeOnceCmd(bf, self, atkAdd)
	end	
end

--战意
activeSkills[24] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if target.hp>self.hp then
			local atkAdd=getPercentParaAdd(self,24,skillIndex)
			addAtkBuffBySkillLv(self,atkAdd,1,24,getSkillLv(self,skillIndex))
			mView.atkChangeOnceCmd(bf, self, atkAdd)
		end
	end	
end

--横扫
activeSkills[25] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	local targetIndex=mSelect.selectTargetIndex(bf, self)
	local tarTeam=mSelect.oppositeTeam(bf, self)
	local atk=cardMgr.getCardAtk(self) 
	if cardMgr.canPhyFighter(self) == true then
		if target~=nil then
			mView.phyAttackCmd(bf,self, target)
			cardMgr.doMinusHpPhy(bf,target,atk)
			self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] = true
		else
			self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] = nil
		end	
		if tarTeam.cards[targetIndex-1]~=nil then
			mView.phyAttackCmd(bf,self, tarTeam.cards[targetIndex-1])
			cardMgr.doMinusHpPhy(bf,tarTeam.cards[targetIndex-1],atk)
		end
		if tarTeam.cards[targetIndex+1]~=nil then
			mView.phyAttackCmd(bf,self, tarTeam.cards[targetIndex+1])
			cardMgr.doMinusHpPhy(bf,tarTeam.cards[targetIndex+1],atk)			
		end	
	end	
end

--连锁攻击
activeSkills[26] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target~=nil and cardMgr.canPhyFighter(self) == true then
		local sameList=mSelect.selectSameTargetList(bf,target)
		local atk=cardMgr.getCardAtk(self) 			
		mView.phyAttackCmd(bf,self, target)
		cardMgr.doMinusHpPhy(bf,target,atk)		
		local sameAtk=getPercentParaAdd(self,26,skillIndex)
		for k,v in pairs(sameList) do
			mView.phyAttackCmd(bf,self, v)
			cardMgr.doMinusHpPhy(bf,v,math.floor(atk*sameAtk/100))
		end
		self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] = true
	else
		self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] = nil
	end	
end

--狙击
activeSkills[27] = function (bf, self,skillIndex)
	local targetList = mSelect.getOppoLessHpList(bf, self,1)
	local atk=getAbsParaAdd(self,27,skillIndex)
	for k,v in pairs(targetList) do
		mView.magicAttackCmd(bf,self,v,27)
		cardMgr.doMinusHpPhy(bf,v,atk)
	end
end

--二重狙击
activeSkills[28] = function (bf, self,skillIndex)
	local targetList = mSelect.getOppoLessHpList(bf, self,2)
	local atk=getAbsParaAdd(self,28,skillIndex)
	for k,v in pairs(targetList) do
		mView.magicAttackCmd(bf,self,v,28)
		cardMgr.doMinusHpPhy(bf,v,atk)
	end
end

--穿透
activeSkills[29] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	local atk=cardMgr.getCardAtk(self) 	
	local atkAdd=getPercentParaAdd(self,29,skillIndex)
	if target~=nil and cardMgr.canPhyFighter(self) == true then
		mView.magicAttackCmd(bf,self,nil,29)
		mView.phyAttackCmd(bf,self, target)
		cardMgr.doMinusHpPhy(bf,target,atk)
		cardMgr.doMinusHeroHp(bf,oppoTeam,atkAdd)	
		self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] = true
	else
		self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] = nil
	end	
end

--反噬
activeSkills[30] = function (bf, self,skillIndex)
	--if self.isNew==true then
	mView.magicAttackCmd(bf,self,nil,30)
	local hpMinus=getAbsParaAdd(self,30,skillIndex)
	local team=bf["team"..self.teamId]
	cardMgr.doMinusHeroHp(bf,team,hpMinus)		
end

--诅咒
activeSkills[31] = function (bf, self,skillIndex)
	mView.magicAttackCmd(bf,self,nil,31)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	cardMgr.doMinusHeroHp(bf,oppoTeam,30)
end

--祈祷
activeSkills[32] = function (bf, self,skillIndex)
	mView.magicAttackCmd(bf,self,nil,32)
	local team=bf["team"..self.teamId]
	cardMgr.doAddHeroHp(bf,team,50)	
end

--守护
activeSkills[33] = function (bf, self,skillIndex)
end

--冰弹
activeSkills[34] = function (bf, self,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,1)
	if  #targetList>0 then
		local target = targetList[1]
		local minusHp=getAbsParaAdd(self,34,skillIndex)
		mView.magicAttackCmd(bf,self,target,34)
		cardMgr.doMinusHpMagic(bf,target,minusHp)	
		local rd=math.random(1,100)
		print("rd "..rd)
		if rd<45 then
			mView.addStateBuffCmd(bf,target,battleType.BATTLE_STATE.SEAL,1)
			addStateBuffBySkillLv(target,battleType.BATTLE_STATE.SEAL,1,34,getSkillLv(self,skillIndex))
		end	
	end	
end

--霜冻新星
activeSkills[35] = function (bf, self,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,3)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][35]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,35)
		for k,v in pairs(targetList) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)				
			if math.random(1,100)<tonumber(paraList[2]) then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.SEAL,1)
				addStateBuffBySkillLv(v,battleType.BATTLE_STATE.SEAL,1,35,skillLv)
			end
		end		
	end	
end

--暴风雪
activeSkills[36] = function (bf, self,skillIndex)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	local minusHp=getAbsParaAdd(self,36,skillIndex)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,36)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)	
			if math.random(1,100)<30 then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.SEAL,1)
				addStateBuffBySkillLv(v,battleType.BATTLE_STATE.SEAL,1,36,getSkillLv(self,skillIndex))
			end
		end	
	end	
end


--落雷
activeSkills[37] = function (bf, self,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,1)
	if  #targetList>0 then
		local act=targetList[1]
		local minusHp=getAbsParaAdd(self,37,skillIndex)
		mView.magicAttackCmd(bf,self,act,37)
		cardMgr.doMinusHpMagic(bf,act,minusHp)	
		if math.random(1,100)<50 then
			mView.addStateBuffCmd(bf,act,battleType.BATTLE_STATE.PHY_SEAL,1)
			addStateBuffBySkillLv(act,battleType.BATTLE_STATE.PHY_SEAL,1,37,getSkillLv(self,skillIndex))
		end
	end	
end

--连环闪电
activeSkills[38] = function (bf, self,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,3)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][38]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,38)
		for k,v in pairs(targetList) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)	
			if math.random(1,100)<tonumber(paraList[2]) then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.PHY_SEAL,1)
				addStateBuffBySkillLv(v,battleType.BATTLE_STATE.PHY_SEAL,1,38,skillLv)
			end
		end	
	end	
end

--雷暴
activeSkills[39] = function (bf, self,skillIndex)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	local minusHp=getAbsParaAdd(self,39,skillIndex)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,39)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)	
			if math.random(1,100)<35 then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.PHY_SEAL,1)
				addStateBuffBySkillLv(v,battleType.BATTLE_STATE.PHY_SEAL,1,39,getSkillLv(self,skillIndex))
			end
		end	
	end	
end

--陷阱
activeSkills[40] = function (bf, self,skillIndex)
	local actNum=getAbsParaAdd(self,40,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,actNum)
	mView.magicGroupAttackCmd(bf, self, targetList,40)
	for k,v in pairs(targetList) do
		if cardMgr.checkSkillExist(v,68)==-1 then
			if math.random(1,100)<65 then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.SEAL,1)
				addStateBuffBySkillLv(v,battleType.BATTLE_STATE.SEAL,1,40,getSkillLv(self,skillIndex))
			end
		else
			mView.magicAttackCmd(bf,v,v,68)					
		end	
	end	
end

--迷魂
activeSkills[41] = function (bf, self,skillIndex)
	local rd=getAbsParaAdd(self,41,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,1)
	if math.random(1,100)<rd and #targetList>0 then
		local act=targetList[1]
		mView.magicAttackCmd(bf,self,act,41)
		if cardMgr.checkSkillExist(act,68)==-1 and cardMgr.canPhyFighter(act) == true then   --脱困
			local tarActList=mSelect.selectExpectRandomCards(bf,act,1)
			if #tarActList>0 then
				local tarAct=tarActList[1]
				local atk=act.atk
				mView.phyAttackCmd(bf,act, tarAct)
				cardMgr.doMinusHpPhy(bf,tarAct,atk)		
			end		
		else
			mView.magicAttackCmd(bf,act,act,68)				
		end	
	end
end

--血炼
activeSkills[43] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	local actNum=getAbsParaAdd(self,43,skillIndex)
	mView.magicAttackCmd(bf,self,target,43)
	if target~=nil then
		cardMgr.doMinusHpMagic(bf,target,actNum)			
	else
		local oppoTeam=mSelect.oppositeTeam(bf, self)
		cardMgr.doMinusHeroHp(bf,oppoTeam,actNum)
	end
	cardMgr.doAddCardHp(bf,self,actNum)		
end

--回春
--activeSkills[44] = function (bf, self,skillIndex)	
--	local actNum=getAbsParaAdd(self,44,skillIndex)	
--	if cardMgr.canCure(self) then
--		mView.magicAttackCmd(bf,self,self,44)
--		cardMgr.doAddCardHp(bf,self,actNum)			
--	end	
--end

--治疗
activeSkills[45] = function (bf, self,skillIndex)	
	local targetList = mSelect.selectLessHpList(bf,self.teamId,1)
	local actNum=getAbsParaAdd(self,45,skillIndex)	
	
	if #targetList>0  then
		if cardMgr.canCure(targetList[1]) then
			mView.magicAttackCmd(bf,self,targetList[1],45)
			cardMgr.doAddCardHp(bf,targetList[1],actNum)	
		end		
	end
end

--甘霖
activeSkills[46] = function (bf, self,skillIndex)	
	local actNum=getAbsParaAdd(self,46,skillIndex)	
	mView.magicGroupAttackCmd(bf, self, bf["team"..self.teamId].cards,46)
	for k,v in pairs(bf["team"..self.teamId].cards) do
		cardMgr.doAddCardHp(bf,v,actNum)			
	end
end


--回魂
activeSkills[48] = function (bf, self,skillIndex)	
	local total=getAbsParaAdd(self,48,skillIndex)	
	local n=1
	mView.magicAttackCmd(bf,self,self,48)
	for k,v in pairs(bf["team"..self.teamId].cemetery) do
		if n<=total then		
			table.remove(bf["team"..self.teamId].cemetery,k)
			table.insert(bf["team"..self.teamId].canditate,v)
			n=n+1
		else
			break
		end	
	end
end

--复活
activeSkills[49] = function (bf, self,skillIndex)	
	mView.magicAttackCmd(bf,self,self,49)
	for k,v in pairs(bf["team"..self.teamId].cemetery) do
		if (v.skill1~=nil and v.skill1==49) or (v.skill2~=nil and v.skill2==49) or (v.skill3~=nil and v.skill3==49) then
		else
			if #bf["team"..self.teamId].cards<10 then
				table.insert(bf["team"..self.teamId].cards,v)
			else
				table.insert(bf["team"..self.teamId].canditate,v)
			end
			table.remove(bf["team"..self.teamId].cemetery,k)
			break
		end
	end
end

--毒液
activeSkills[50] = function (bf, self,skillIndex)	
	local target = mSelect.selectTarget(bf, self)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][50]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	local buffNum=tonumber(paraList[2])
	if target ~= nil then
		mView.magicAttackCmd(bf,self,target,50)
		cardMgr.doMinusHpMagic(bf,target,minusHp)		
		local buff=checkBuffBySkillLv(target.data.buff.hpDebuff,50,skillLv)
		if buff~=nil then
		else
			if cardMgr.canDebuff(target) then
				mView.addDeBuffCmd(bf, target, 50,buffNum)
				addHpDeBuffBySkillLv(target,-buffNum,-1,50,skillLv)
			end	
		end
	end	
end

--毒雾
activeSkills[51] = function (bf, self,skillIndex)	
	local targetList = mSelect.selectOppoRandomCards(bf, self,3)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][51]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	local buffNum=tonumber(paraList[2])
	mView.magicGroupAttackCmd(bf, self, targetList,51)
	for k,v in pairs(targetList) do
		cardMgr.doMinusHpMagic(bf,v,minusHp)	
		local buff=checkBuffBySkillLv(v.data.buff.hpDebuff,51,skillLv)
		if buff~=nil then
		else
			if cardMgr.canDebuff(v) then
				mView.addDeBuffCmd(bf, v, 51,buffNum)
				addHpDeBuffBySkillLv(v,-buffNum,-1,51,skillLv)
			end
		end
	end	
end

--火球
activeSkills[52] = function (bf, self,skillIndex)
	local targetList = mSelect.selectOppoRandomCards(bf, self,1)
	if  #targetList>0 then
		local target=targetList[1]
		local skillLv=getSkillLv(self,skillIndex)
		local paras=mTData["skill"][52]["para"..skillLv]
		local paraList = splitWithTrim(paras, ",")
		local minMinus=tonumber(paraList[1])
		local maxMinus=tonumber(paraList[2])
		minusHp=math.random(minMinus,maxMinus)
		mView.magicAttackCmd(bf,self,target,52)
		cardMgr.doMinusHpMagic(bf,target,minusHp)						
	end
end


--火墙
activeSkills[53] = function (bf, self,skillIndex)	
	local targetList = mSelect.selectOppoRandomCards(bf, self,3)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][52]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minMinus=tonumber(paraList[1])
	local maxMinus=tonumber(paraList[2])
	minusHp=math.random(minMinus,maxMinus)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, self, targetList,53)
		for k,v in pairs(targetList) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)					
		end	
	end	
end

--烈焰风暴
activeSkills[54] = function (bf, self,skillIndex)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	local skillLv=getSkillLv(self,skillIndex)
	local paras=mTData["skill"][54]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minMinus=tonumber(paraList[1])
	local maxMinus=tonumber(paraList[2])
	minusHp=math.random(minMinus,maxMinus)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,54)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)					
		end	
	end	
end


--烈火焚神
activeSkills[56] = function (bf, self,skillIndex)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	local buffNum=getAbsParaAdd(self,56,skillIndex)	
	mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,56)
	for k,v in pairs(oppoTeam.cards) do
		local buff=checkBuffBySkillLv(v.data.buff.hpDebuff,56,getSkillLv(self,skillIndex))
		if buff~=nil then
		else
			if cardMgr.canDebuff(v) then
				mView.addDeBuffCmd(bf, v, 56,buffNum)
				addHpDeBuffBySkillLv(v,-buffNum,-1,56,getSkillLv(self,skillIndex))			
			end	
		end
	end
end

--削弱
activeSkills[57] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	local num=getAbsParaAdd(self,57,skillIndex)	
	if target~=nil then
		mView.magicAttackCmd(bf,self,target,57)
		local buff=checkBuffBySkillLv(target.data.buff.atk,57,getSkillLv(self,skillIndex))
		mView.atkChangeCmd(bf, target, -num)
		if buff~=nil then
			buff.atkAdd=buff.atkAdd-num
		else
			addAtkBuffBySkillLv(target,-num,-1,57,getSkillLv(self,skillIndex))
		end
	end
end

--群体削弱
activeSkills[58] = function (bf, self,skillIndex)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	local num=getAbsParaAdd(self,58,skillIndex)	
	mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,58)
	for k,v in pairs(oppoTeam.cards) do
		local buff=checkBuffBySkillLv(v.data.buff.atkDebuff,58,getSkillLv(self,skillIndex))
		mView.atkChangeCmd(bf, v, -num)
		if buff~=nil then
			buff.atkAdd=buff.atkAdd-num
		else
			addAtkBuffBySkillLv(v,-num,-1,58,getSkillLv(self,skillIndex))
		end
	end
end


--献祭
activeSkills[64] = function (bf, self,skillIndex)
	if #bf["team"..self.teamId].cards>1 then
		local num=getPercentParaAdd(self,64,skillIndex)	
		local list={}
		for k,v in pairs(bf["team"..self.teamId].cards) do
			if v~= self then
				table.insert(list,k)
			end			
		end
		local sel=list[math.random(#list)]
		mView.magicAttackCmd(bf,self,bf["team"..self.teamId].cards[sel],64)
		mView.atkChangeCmd(bf, bf["team"..self.teamId].cards[sel], num)
		cardMgr.doDeadClean(bf["team"..self.teamId].cards[sel])
		addAtkBuffBySkillLv(self,num,-1,64,getSkillLv(self,skillIndex))
	end	
end

--送还
activeSkills[70] = function (bf, self,skillIndex)
	--上场回合触发
	--if self.isNew==true then
	local target = mSelect.selectTarget(bf, self)
	local tarTeam=mSelect.oppositeTeam(bf, self)	
	if target ~= nil then
		mView.magicAttackCmd(bf,self,target,70)
		cardMgr.doDeadClean(target)
		table.insert(tarTeam.canditate,target)	
	end
end

--裂伤
activeSkills[71] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target~=nil then
		mView.magicAttackCmd(bf,self,target,71)
		mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.NON_CURE,1)
		addStateBuffBySkillLv(target,battleType.BATTLE_STATE.NON_CURE,1,71,getSkillLv(self,skillIndex))
	end	
end

--弱点攻击
activeSkills[72] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	if target~=nil then
		mView.magicAttackCmd(bf,self,target,72)
		local skillIndex1=cardMgr.checkSkillExist(target,62)
		if skillIndex1>=1 then
			addSkillBan(target,skillIndex1,1)
		end	
		local skillIndex2=cardMgr.checkSkillExist(target,63)
		if skillIndex2>=1 then
			addSkillBan(target,skillIndex2,1)
		end	
	end	
end

--摧毁
activeSkills[73] = function (bf, self,skillIndex)
	--上场回合触发
	--if self.isNew==true then
	local target = mSelect.selectTarget(bf, self)
	local tarTeam=mSelect.oppositeTeam(bf, self)	
	if target ~= nil then
		mView.magicAttackCmd(bf,self,target,73)
		cardMgr.doDeadByEnemy(bf,target)
		table.insert(tarTeam.cemetery,target)	
	end
end

--封印
activeSkills[74] = function (bf, self,skillIndex)
	--上场回合触发
	--if self.isNew==true then
	local oppoTeam=mSelect.oppositeTeam(bf, self)	
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,74)
		for k,v in pairs(oppoTeam.cards) do
			if cardMgr.checkSkillExist(v,68)==-1 then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.SEAL,1)
				addStateBuffBySkillLv(v,battleType.BATTLE_STATE.SEAL,1,74,getSkillLv(self,skillIndex))
			else
				mView.magicAttackCmd(bf,v,v,68)	
			end	
		end	
	end
end

--英雄技能带来的狙击
activeSkills[91] = function (bf, self,para)
	local targetList = mSelect.getOppoLessHpList(bf, self,1)
	for k,v in pairs(targetList) do
		mView.magicAttackCmd(bf,self,v,91)
		cardMgr.doMinusHpPhy(bf,v,para)
	end
end

--英雄技能带来的二重狙击
activeSkills[92] = function (bf, self,para)
	local targetList = mSelect.getOppoLessHpList(bf, self,2)
	for k,v in pairs(targetList) do
		mView.magicAttackCmd(bf,self,v,92)
		cardMgr.doMinusHpPhy(bf,v,para)
	end
end

--英雄技能带来的战意
activeSkills[94] = function (bf, self,para)
	local target = mSelect.selectTarget(bf, self)
	if target ~= nil then
		if target.hp>self.hp then
			local atkAdd= math.floor(cardMgr.getCardAtk(self) *para/100)
			addAtkBuffBySkillLv(self,atkAdd,1,94,1)
			mView.atkChangeOnceCmd(bf, self, atkAdd)
		end
	end	
end

--色胆包天
activeSkills[121] = function (bf, self,skillIndex)
	local targetList = mSelect.getOppoLessHpList(bf, self,1)
	if #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf, self, target,121)
		cardMgr.doMinusHpPhy(bf,target,2000)
	end
end

