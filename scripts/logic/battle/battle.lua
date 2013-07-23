local ipairs,pairs,printTable,print,table=ipairs,pairs,printTable,print,table
local battleType=require("logic.constants.BattleType")
local skillType=require "logic.constants.SkillType"
local mTData = require("template.gamedata").data
local cardMgr=require "logic.battle.cardMgr"
local mSkill  = require "logic.battle.skill"
local heroSkill  = require "logic.battle.heroSkill"
local passive  = require "logic.battle.passive"
local mSelect =require "logic.battle.select"
local mView =require "logic.battle.view"
local mBattleData=require("logic.battle.data")

module("logic.battle.battle")


--首先触发法宝技能，然后触发 只出场回合的技能，再触发新上场的卡牌技能
function battleStart(bf)	
	local team1=bf.team1
	local team2=bf.team2
	
	--如果有死亡的卡片，把后面卡牌位置提前
	checkCardIndex(team1)
	checkCardIndex(team2)
	--触发法宝
	triggerHeroMagic(bf,team1.hero)
	triggerHeroMagic(bf,team2.hero)
	
	--触发只出场回合的技能
	triggerTeamSkill(bf,team1,1)
	triggerTeamSkill(bf,team2,1)
	
	--触发新上场的卡牌技能
	triggerTeamSkill(bf,team1,2)
	triggerTeamSkill(bf,team2,2)
	
	if isBattleEnd(bf) == true then
		battleEnd(bf)
		return bf
	end
	for index=1,team1.battleCardNum do
		if team1.cards[index]~=nil  then
			fighter=team1.cards[index]
			if cardMgr.canSkillFighter(fighter) == true and fighter.isNew==false then
				skillFight(bf, fighter,3)
			end
			if cardMgr.canPhyFighter(fighter) == true then
				phyFight(bf, fighter)
			end
			if fighter.isNew==true then
				fighter.isNew=false
			end
			for k,v in pairs(fighter.data.buff.addSkill) do
				doActionEndSkills(bf,fighter,v.skillTid,v.para)				
			end
			--检查buff状态
			cleanBuffStatus(fighter)	
			if isBattleEnd(bf) == true then
				battleEnd(bf)
				return bf
			end
		end
	end
	for index=1,team2.battleCardNum do
		if team2.cards[index]~=nil  then
			fighter=team2.cards[index]
			if cardMgr.canSkillFighter(fighter) == true and fighter.isNew==false then
				skillFight(bf, fighter,3)
			end
			if cardMgr.canPhyFighter(fighter) == true then
				phyFight(bf, fighter)
			end		
			if fighter.isNew==true then
				fighter.isNew=false
			end
			for k,v in pairs(fighter.data.buff.addSkill) do
				doActionEndSkills(bf,fighter,v.skillTid,v.para)				
			end
			cleanBuffStatus(fighter)
			if isBattleEnd(bf) == true then
				battleEnd(bf)
				return bf
			end
		end	
	end
end

function triggerTeamSkill(bf,team,kind)
	for index=1,team.battleCardNum do
		if team.cards[index]~=nil  then
			fighter=team.cards[index]
			if kind==1 then
				doDeBuffAction(bf,fighter)  --计算debuff
			end	
			if cardMgr.canSkillFighter(fighter) == true  then
				skillFight(bf, fighter,kind)
			end		
		end	
	end
end

function checkCardIndex(team)
	local sIndex=1
	local eIndex=2
	while eIndex<=team.battleCardNum  do
		if team.cards[sIndex]==nil then
			while team.cards[eIndex]==nil and eIndex<=team.battleCardNum  do
				eIndex=eIndex+1
			end
			if team.cards[eIndex]~=nil then
				team.cards[sIndex]=team.cards[eIndex]
				team.cards[eIndex]=nil
			end	
		end	
		sIndex=sIndex+1
		if eIndex<=sIndex then
			eIndex=sIndex+1
		end
	end
	team.battleCardNum=#team.cards
end

function triggerHeroMagic(bf,hero)
	for k,v in pairs(hero.magicList) do	
		heroSkill.checkHelloSkillEnable(bf,hero,v)
	end
end

function cleanBuff(buffList)
	for k,v in pairs(buffList) do
		if v.roundNum>0 then
			v.roundNum=v.roundNum-1
		end
		if v.roundNum==0 then
			buffList[k]=nil
		end
	end	
end
function cleanBuffStatus(self)
	cleanBuff(self.data.buff.atk)
	cleanBuff(self.data.buff.hp)
	cleanBuff(self.data.buff.state)
	cleanBuff(self.data.buff.hpDebuff)
	cleanBuff(self.data.buff.addSkill)
	for k,v in pairs(self.data.buff.skillBan) do
		if self.data.buff.skillBan[k]>0 then
			self.data.buff.skillBan[k]=self.data.buff.skillBan[k]-1
		end
		if self.data.buff.skillBan[k]==0 then
			self.data.buff.skillBan[k]=nil
		end
	end	
end
function doDeBuffAction(bf,self)
	--debuff ，扣除生命
	local minus=0
	for k,v in pairs(self.data.buff.hpDebuff) do
		if v.roundNum~=-1 and v.roundNum>=1 then
			minus=minus+v.hpAdd
		end	
	end
	if minus>0 then
		cardMgr.doMinusCardHp(bf,self,minus)
	end	
end 

--技能攻击
function skillFight(bf, self,kind)
	local cardTmp= mTData["card"][self.tid]
	for k=1,3 do		
		if kind==1 and self.isNew==true then
			if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) and skillType.FIRST_ROUND_TRIG[cardTmp["skill"..k]]~=nil  then
				doActiveSkills(bf,self,cardTmp["skill"..k],k)		
			end
		elseif kind==2 and self.isNew==true then
			if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) and skillType.FIRST_ROUND_TRIG[cardTmp["skill"..k]]==nil then
				doActiveSkills(bf,self,cardTmp["skill"..k],k)		
			end
		elseif kind==3 and self.isNew==false then
			if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) and skillType.FIRST_ROUND_TRIG[cardTmp["skill"..k]]==nil then
				doActiveSkills(bf,self,cardTmp["skill"..k],k)		
			end	
		end	
	end	
	--触发战斗中动态添加的技能
	if kind==3 then
		for k,v in pairs(self.data.buff.addSkill) do
			doActiveSkills(bf,self,v.skillTid,v.para)				
		end
	end
end

function phyFIghtCal(bf,self)
	local target = mSelect.selectTarget(bf, self)
	local atk=cardMgr.getCardAtk(self) 
	mView.phyAttackCmd(bf,self, target)
	if target~=nil then
		local cardTmp= mTData["card"][self.tid]
		
		--触发攻击方物理攻击技能
		for k=1,3  do
			if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) then
				atk=doBefPhyAttack(bf,self,cardTmp["skill"..k],k,atk)
			end
		end	

		--触发战斗中动态添加的技能
		for k,v in pairs(self.data.buff.addSkill) do
			atk=doBefPhyAttack(bf,self,v.skillTid,v.para,atk)
		end

		--触发被攻击方物理攻击时技能
		local cardTmp2= mTData["card"][target.tid]
		for k=1,3  do
			if cardTmp2["skill"..k]~=nil and cardTmp2["skill"..k]~=0 and (target.data.buff.skillBan[k]==nil or target.data.buff.skillBan[k]==0) then
				atk=doBefPhyAttackedSkills(bf,self,cardTmp2["skill"..k],k,atk)
			end
		end	

		--触发战斗中动态添加的技能
		for k,v in pairs(self.data.buff.addSkill) do
			atk=doBefPhyAttackedSkills(bf,self,v.skillTid,v.para,atk)
		end

		cardMgr.doMinusHpPhy(bf,target,atk)		
	else
		local oppoTeam=mSelect.oppositeTeam(bf, self)
		cardMgr.doMinusHeroHp(bf,oppoTeam,atk)		
	end
	return atk
end


--普通攻击
function phyFight(bf, self)
	local target = mSelect.selectTarget(bf, self)
	local atkNum=phyFIghtCal(bf,self)	
	if target~=nil then
		local cardTmp= mTData["card"][self.tid]
		--触发攻击方物理攻击后技能
		for k=1,3  do
			if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) then
				doAftPhyAttack(bf,self,cardTmp["skill"..k],k,atk)
			end
		end	
		--触发战斗中动态添加的技能
		for k,v in pairs(self.data.buff.addSkill) do
			doAftPhyAttack(bf,self,v.skillTid,v.para,atk)				
		end
		--受到物理攻击时触发
		if target.hp>0 then
			local cardTmp2= mTData["card"][target.tid]
			for k=1,3  do
				if cardTmp2["skill"..k]~=nil and cardTmp2["skill"..k]~=0 and (target.data.buff.skillBan[k]==nil or target.data.buff.skillBan[k]==0) then
					doPhyAttackedSkills(bf,self,cardTmp2["skill"..k],k)		
				end
			end			
		end
		--触发战斗中动态添加的技能
		for k,v in pairs(self.data.buff.addSkill) do
			doPhyAttackedSkills(bf,self,v.skillTid,v.para)				
		end
	else
		
	end		
end

function doStateBuffAfterPhy(bf,self,atkNum)
	local state=self.data.buff.state[battleType.BATTLE_STATE.BLOOD_SUCK]
	if state~=nil and state.roundNum~=0 then
		local buff=mSkill.checkSkilledBuff(self.data.buff.atk,buff.skillTid)
		if buff~=nil then
			--已经有叠加过
			buff.atkAdd=buff.atkAdd+state.para
		else
			mSkill.addAtkBuffBySkillLv(self,buff.para,-1,buff.skillTid,buff.skillLv)
		end
		
	end

	local state=self.data.buff.state[battleType.BATTLE_STATE.BLOOD_ABSORB]
	if state~=nil and state.roundNum~=0 then
		local hpAdd=math.floor(state.para*atkNum/100)
		cardMgr.doAddCardHp(bf,self,hpAdd)		
	end
end

function doActiveSkills(bf,self,skillTid,skillIndex)
	local skillFunc = mSkill.activeSkills[skillTid]
	if skillFunc~=nil then
		skillFunc(bf,self,skillIndex)
	end	
end

function doActionEndSkills(bf,self,skillTid,skillIndex)
	local skillFunc = passive.actionEndSkills[skillTid]
	if skillFunc~=nil then
		skillFunc(bf,self,skillIndex)
	end
	
end

function doPhyAttackedSkills(bf,target,skillTid,skillIndex,atkNum)
	local skillFunc = passive.phyAttackedSkills[skillTid]
	if skillFunc~=nil then
		skillFunc(bf,target,skillIndex,atkNum)
	end	
end

-- function doMagicAttackedSkills(bf,self,skillTid,skillIndex)
	-- local skillFunc = passive.magicAttaedSkills[skillTid]
	-- if skillFunc~=nil then
		-- skillFunc(bf,self,skillIndex)
	-- end	
-- end

function doBefPhyAttackedSkills(bf,self,skillTid,skillIndex,atkNum)
	local skillFunc = passive.befPhyAttackedSkills[skillTid]
	local rt=atkNum
	if skillFunc~=nil then
		rt=skillFunc(bf,self,skillIndex,atkNum)
	end	
	return rt
end

function doBefPhyAttack(bf,self,skillTid,skillIndex,atkNum)
	local skillFunc = passive.befPhyAttack[skillTid]
	local rt=atkNum
	if skillFunc~=nil then
		rt=skillFunc(bf,self,skillIndex,atkNum)
	end	
	return rt
end


function doAftPhyAttack(bf,self,skillTid,skillIndex)
	local skillFunc = passive.aftPhyAttack[skillTid]
	if skillFunc~=nil then
		skillFunc(bf, self,skillIndex)
	end	
end


function isTeamDefeated(team)
	if #team.cards<1 or team.hero.hp<=0 then
		return true
	end	
	return false
end

function isBattleEnd(bf)
	if isTeamDefeated(bf.team1) or isTeamDefeated(bf.team2) then
		return true
	else
		return false
	end
end

function battleEnd(bf)
	if bf.status == battleType.FIELD_STATUS.END then
		return
	end	
	bf.status=battleType.FIELD_STATUS.END
	if isTeamDefeated(bf.team1) then
		bf.winnerId=bf.team1.id
		bf.team2.status=battleType.TEAM_STATUS.WIN	
		bf.team1.status=battleType.TEAM_STATUS.LOSE	
	end
	if isTeamDefeated(bf.team2) then
		bf.winnerId=bf.team2.id
		bf.team1.status=battleType.TEAM_STATUS.WIN
		bf.team2.status=battleType.TEAM_STATUS.LOSE			
	end	
	local battle = mBattleData.getBattle(bf.id)
	local callback = battle.callback

	callback(bf, battle.params)

	
end