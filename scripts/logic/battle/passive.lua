local assert,math,print,pairs,table,math,tonumber = assert,math,print,pairs,table,math,tonumber

local mView = require ("logic.battle.view")
local battleType = require ("logic.constants.BattleType")
local mTData = require("template.gamedata").data
local skill =require "logic.battle.skill"
local cardMgr=require "logic.battle.cardMgr"
module ("logic.battle.passive")

befPhyAttackedSkills={} --受到物理攻击前触发
befMagicAttackedSkills={} --受到法术攻击前触发 
phyAttackedSkills={}  --受到物理攻击触发
-- magicAttaedSkills={}  --受到法术攻击触发
befPhyAttack={}  --物理攻击前触发
aftPhyAttack={}  --物理攻击后触发
deadSkills={}  --死亡时触发 
actionEndSkills={} --行动结束时触发


function getSelfIndex(bf,self)
	local team=bf["team"..self.teamId]
	for k,v in pairs(team.cards) do
		if v==self then
			return k
		end	
	end
	return 1
end

--狂热
phyAttackedSkills[18] = function (bf, self,skillIndex)
	local atkAdd=skill.getAbsParaAdd(self,18,skillIndex)
	addAtkBuffBySkillLv(self,atkAdd,-1,18,skill.getSkillLv(self,skillIndex))
	mView.magicAttackCmd(bf,self,self,18)
	mView.atkChangeOnceCmd(bf, self, atkAdd)
end

--反击
phyAttackedSkills[20] = function (bf, self,skillIndex)
	local target=mSelect.selectTarget(bf, self)
	local atk=skill.getAbsParaAdd(self,20,skillIndex)
	mView.magicAttackCmd(bf,self,target,20)	
	cardMgr.doMinusHpPhy(bf,target,atk)	
end

--盾刺
phyAttackedSkills[21] = function (bf, self,skillIndex)
	local team=bf["team"..self.teamId]
	local tarTeam=mSelect.oppositeTeam(bf, self)
	local target=mSelect.selectTarget(bf, self)
	local index=getSelfIndex(bf,self)	
	local atk=skill.getAbsParaAdd(self,21,skillIndex)
	
	if tarTeam.cards[index-1]~=nil then
		mView.magicAttackCmd(bf,self,tarTeam.cards[index-1],21)	
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[index-1],atk)			
	end
	mView.magicAttackCmd(bf,self,target,21)	
	cardMgr.doMinusHpPhy(bf,target,atk)	
	if tarTeam.cards[index+1]~=nil then
		mView.magicAttackCmd(bf,self,tarTeam.cards[index+1],21)	
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[index+1],atk)			
	end	
end




--燃烧
phyAttackedSkills[55] = function (bf, self,skillIndex)	
	local target=mSelect.selectTarget(bf, self)
	local number=skill.getAbsParaAdd(self,55,skillIndex)
	if target ~= nil then
		mView.magicAttackCmd(bf,self,target,55)	
		local buff=skill.checkBuffBySkillLv(target.data.buff.hpDebuff,55,skill.getSkillLv(self,skillIndex))
		if buff~=nil then
		else
			if cardMgr.canDebuff(target) then
				skill.addHpDeBuffBySkillLv(target,-number,-1,55,skill.getSkillLv(self,skillIndex))
			end	
		end
	end	
end

--英雄技能带来的狂热
phyAttackedSkills[90] = function (bf, self,para)
	skill.addAtkBuffBySkillLv(self,para,-1,90,1)
	mView.magicAttackCmd(bf,self,self,90)
	mView.atkChangeOnceCmd(bf, self, para)
end

--英雄技能带来的反击
phyAttackedSkills[95] = function (bf, self,para)
	local target=mSelect.selectTarget(bf, self)
	mView.magicAttackCmd(bf,self,target,95)	
	cardMgr.doMinusHpPhy(bf,target,para)	
end

--英雄技能带来的盾刺
phyAttackedSkills[109] = function (bf, self,para)
	local team=bf["team"..self.teamId]
	local tarTeam=mSelect.oppositeTeam(bf, self)
	local target=mSelect.selectTarget(bf, self)
	local index=getSelfIndex(bf,self)	
	if tarTeam.cards[index-1]~=nil then
		mView.magicAttackCmd(bf,self,tarTeam.cards[index-1],109)	
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[index-1],para)			
	end
	mView.magicAttackCmd(bf,self,target,109)	
	cardMgr.doMinusHpPhy(bf,target,para)	
	if tarTeam.cards[index+1]~=nil then
		mView.magicAttackCmd(bf,self,tarTeam.cards[index+1],109)	
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[index+1],para)			
	end	
end

--天王镜铠
phyAttackedSkills[122] = function (bf, self,skillIndex)
	local team=bf["team"..self.teamId]
	local tarTeam=mSelect.oppositeTeam(bf, self)
	local target=mSelect.selectTarget(bf, self)
	local index=getSelfIndex(bf,self)	
	if tarTeam.cards[index-1]~=nil then
		mView.magicAttackCmd(bf,self,tarTeam.cards[index-1],122)	
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[index-1],1500)			
	end
	mView.magicAttackCmd(bf,self,target,122)	
	cardMgr.doMinusHpPhy(bf,target,1500)	
	if tarTeam.cards[index+1]~=nil then
		mView.magicAttackCmd(bf,self,tarTeam.cards[index+1],122)	
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[index+1],1500)			
	end	
end

--战意
aftPhyAttack[19] = function (bf, self,skillIndex)
	local buff=skill.checkSkilledBuff(self.data.buff.atk,19)
	local num=skill.getAbsParaAdd(self,19,skillIndex)
	mView.magicAttackCmd(bf,self,self,19)
	mView.atkChangeCmd(bf, self, num)
	if buff~=nil then
		--已经有叠加过
		buff.atkAdd=buff.atkAdd+num
	else
		local atkAdd=num
		skill.addAtkBuffBySkillLv(self,atkAdd,-1,19,skill.getSkillLv(self,skillIndex))
	end
	
end

--疾病
aftPhyAttack[59] = function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	local num=skill.getAbsParaAdd(self,59,skillIndex)	
	if target~=nil then
		mView.magicAttackCmd(bf,self,target,59)	
		mView.atkChangeCmd(bf, self, -num)
		local buff=skill.checkBuffBySkillLv(target.data.buff.atk,59,skill.getSkillLv(self,skillIndex))
		if buff~=nil then
			buff.atkAdd=buff.atkAdd-num
		else
			skill.addAtkBuffBySkillLv(target,-num,-1,59,skill.getSkillLv(self,skillIndex))
		end
	end
end
--瘟疫
aftPhyAttack[60] = function (bf, self,skillIndex)
	local oppoTeam=mSelect.oppositeTeam(bf, self)
	local num=skill.getAbsParaAdd(self,60,skillIndex)	
	mView.magicGroupAttackCmd(bf, self, oppoTeam.cards,60)
	for k,v in pairs(oppoTeam.cards) do
		mView.atkChangeCmd(bf, v, -num)
		local buff=skill.checkBuffBySkillLv(v.data.buff.atk,60,skill.getSkillLv(self,skillIndex))
		if buff~=nil then
			buff.atkAdd=buff.atkAdd-num
		else
			skill.addAtkBuffBySkillLv(v,-num,-1,60,skill.getSkillLv(self,skillIndex))
		end
	end
end

--吸血
aftPhyAttack[42] = function (bf, self,skillIndex,atkNum)
	local number=skill.getAbsParaAdd(self,42,skillIndex)
	mView.magicAttackCmd(bf,self,self,42)	
	cardMgr.doAddCardHp(bf,self,math.floor(atkNum*number/100))	
end

--英雄技能带来的嗜血
aftPhyAttack[87] = function (bf, self,para)
	skill.addAtkBuffBySkillLv(self,para,-1,87,1)
	mView.magicAttackCmd(bf,self,self,87)
	mView.atkChangeOnceCmd(bf, self, para)
end

--英雄技能带来的吸血
aftPhyAttack[88] = function (bf, self,para,atkNum)
	mView.magicAttackCmd(bf,self,self,88)	
	cardMgr.doAddCardHp(bf,self,math.floor(atkNum*para/100))	
end

--格挡
befPhyAttackedSkills[61] = function (bf,self,skillIndex,atkNum)
	if atkNum>0 then
		local num=skill.getAbsParaAdd(self,61,skillIndex)	
		mView.magicAttackCmd(bf,self,self,61)		
		if ackNum>num then
			return ackNum-num
		end	
	end	
	return 0
end

--闪避
befPhyAttackedSkills[63] = function (bf,self,skillIndex,atkNum)
	if atkNum>0 then
		local num=skill.getAbsParaAdd(self,61,skillIndex)	
		if math.random(100)<num then
			mView.magicAttackCmd(bf,self,self,63)		
			return 0
		else
			return atkNum	
		end	
	end	
	return 0
end

--玄龟甲
befPhyAttackedSkills[75] = function (bf,self,skillIndex,atkNum)
	if atkNum>0 then
		local num=skill.getAbsParaAdd(self,75,skillIndex)	
		if atkNum>num then
			mView.magicAttackCmd(bf,self,self,75)		
			return num
		else
			return atkNum	
		end	
	end	
	return 0
end

--英雄技能带来的群体闪避
befPhyAttackedSkills[103] = function (bf,self,para,atkNum)
	if atkNum>0 then
		if math.random(100)<para then
			mView.magicAttackCmd(bf,self,self,103)		
			return 0
		else
			return atkNum	
		end	
	end	
	return 0
end

--英雄技能带来的玄武盾
befPhyAttackedSkills[113] = function (bf,self,para,atkNum)
	if atkNum>0 then
		if atkNum>para then
			mView.magicAttackCmd(bf,self,self,113)		
			return para
		else
			return atkNum	
		end	
	end	
	return 0
end

--英雄技能带来的护心镜
befPhyAttackedSkills[114] = function (bf,self,para,atkNum)
	if atkNum>0 then
		mView.magicAttackCmd(bf,self,self,114)
		if atkNum>para then	
			return atkNum-para
		else
			return 0	
		end	
	end	
	return 0
end


--魔甲
befMagicAttackedSkills[62] = function (bf,self,skillIndex,atkNum)
	local num=skill.getAbsParaAdd(self,62,skillIndex)	
	mView.magicAttackCmd(bf,self,self,62)		
	if ackNum>num then
		return num
	else
		return atkNum
	end	
end

--免疫
befMagicAttackedSkills[67] = function (bf,self,skillIndex,atkNum)
	mView.magicAttackCmd(bf,self,self,67)	
	return 0
end

--英雄技能带来的群体魔甲
befPhyAttackedSkills[116] = function (bf,self,para,atkNum)
	mView.magicAttackCmd(bf,self,self,116)		
	if ackNum>para then
		return para
	else
		return atkNum
	end	
end

--英雄技能带来的群体反射
befPhyAttackedSkills[117] = function (bf,self,para,atkNum)
	mView.magicAttackCmd(bf,self,self,117)	
	local target = mSelect.selectTarget(bf, self)
	if target~=nil then
		cardMgr.doMinusCardHp(bf,target,para)
	end
	return 0
end

--穷追猛打
befPhyAttack[69] = function (self,skillIndex,atkNum)
	local target = mSelect.selectTarget(bf, self)
	local num=skill.getPercentParaAdd(self,69,skillIndex)	
	if target~=nil and #target.data.buff.hpDebuff>0 then
		mView.magicAttackCmd(bf,self,target,69)	
		atkNum=atkNum+num
	end
	
	return atkNum
end


--英雄技能带来的穷追猛打
befPhyAttack[110] = function (bf,self,para,atkNum)
	local target = mSelect.selectTarget(bf, self)
	if target~=nil and #target.data.buff.hpDebuff>0 then
		mView.magicAttackCmd(bf,self,target,110)	
		atkNum=atkNum+para
	end
	
	return atkNum
end

--往生咒
deadSkills[47]= function (bf, self,skillIndex)
	local number=skill.getAbsParaAdd(self,47,skillIndex)
	if math.random(1,100)<number then
		for k,v in pairs(bf["team"..self.teamId].cemetery) do
			if v==self then
				mView.magicAttackCmd(bf,self,self,47)	
				table.remove(bf["team"..self.teamId].cemetery,k)
				table.insert(bf["team"..self.teamId].canditate,v)
				break
			end
		end
	end
end

--自爆
deadSkills[65]= function (bf, self,skillIndex)
	local target = mSelect.selectTarget(bf, self)
	local targetIndex=smSelect.selectTargetIndex(bf, self)
	local tarTeam=mSelect.oppositeTeam(bf, self)
	local atk=skill.getAbsParaAdd(self,65,skillIndex)	
	mView.magicAttackCmd(bf,self,self,65)		
	if target~=nil then
		mView.phyAttackCmd(bf,self, target)
		cardMgr.doMinusHpPhy(bf,target,atk)
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

--英雄技能带来的群体回春
deadSkills[111] = function (bf, self,para)	
	local target = mSelect.selectTarget(bf, self)
	local targetIndex=smSelect.selectTargetIndex(bf, self)
	local tarTeam=mSelect.oppositeTeam(bf, self)
	local atk=skill.getAbsParaAdd(self,65,skillIndex)	
	mView.magicAttackCmd(bf,self,self,111)		
	if target~=nil then
		mView.phyAttackCmd(bf,self, target)
		cardMgr.doMinusHpPhy(bf,target,para)
	end	
	if tarTeam.cards[targetIndex-1]~=nil then
		mView.phyAttackCmd(bf,self, tarTeam.cards[targetIndex-1])
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[targetIndex-1],para)
	end
	if tarTeam.cards[targetIndex+1]~=nil then
		mView.phyAttackCmd(bf,self, tarTeam.cards[targetIndex+1])
		cardMgr.doMinusHpPhy(bf,tarTeam.cards[targetIndex+1],para)			
	end		
end



--回春
actionEndSkills[44] = function (bf, self,skillIndex)	
	local actNum=skill.getAbsParaAdd(self,44,skillIndex)	
	if cardMgr.canCure(self) then
		mView.magicAttackCmd(bf,self,self,44)
		cardMgr.doAddCardHp(bf,self,actNum)			
	end	
end

--英雄技能带来的群体回春
actionEndSkills[97] = function (bf, self,para)	
	if cardMgr.canCure(self) then
		mView.magicAttackCmd(bf,self,self,97)
		cardMgr.doAddCardHp(bf,self,para)			
	end	
end


