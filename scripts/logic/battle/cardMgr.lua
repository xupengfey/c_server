local assert,math,print,pairs,table,cloneTable,inRate,io,printTable,package = assert,math,print,pairs,table,cloneTable,inRate,io,printTable,package
local battleType = require("logic.constants.BattleType")
local team=require "logic.battle.team"
local mTData = require("template.gamedata").data
local mSelect =require "logic.battle.select"
local mView=require "logic.battle.view"
module("logic.battle.cardMgr")

function getCardAtk(self)
	local atk=self.atk
	for k,v in pairs(self.data.buff.atk) do
		atk=atk+v.atkAdd
	end
	return atk
end
--计算卡牌的总血量，当前血量加上buff
function getCardTotalHp(self)
	local hp=self.hp
	for k,v in pairs(self.data.buff.hp) do
		if v.roundNum~=-1 and v.roundNum>=1 then
			hp=hp+v.hpAdd
		end	
	end
	return hp
end

function doAddHeroHp(bf,team,add)
	team.hero.hp=team.hero.hp+add
	mView.hpChangeCmd(bf, nil, add)	
end

function doMinusHeroHp(bf,team,minus)
	if team.hero.hp>=minus then
		team.hero.hp=team.hero.hp-minus		
	else
		team.hero.hp=0
	end
	mView.hpChangeCmd(bf, nil, -minus)	
end

function doAddCardHp(bf,self,add)
	self.hp=self.hp+add
	if self.hp>self.hpTotal then
		self.hp=self.hpTotal
	end
	mView.hpChangeCmd(bf, self, add)
end

function doMinusCardHp(bf,self,minus)
	if getCardTotalHp(self)-minus-self.buffHpMinus<=0 then
		doDeadByEnemy(bf,self)
	else
		print("minus0"..self.hp)
		if self.hp-minus>0 then
			self.hp=self.hp-minus
		else
			self.buffHpMinus=self.buffHpMinus+(minus-self.hp)
			self.hp=0
		end
		print("minus1"..self.hp)
	end
	mView.hpChangeCmd(bf, self, -minus)
end


function doMinusHpPhy(bf,self,minus)
	-- local cardTmp= mTData["card"][self.tid]
	-- for k=1,3 then
		-- if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) then
			-- local skillTid=cardTmp["skill"..k]
			-- local skillFunc = passive.befPhyAttackedSkills[skillTid]
			-- if skillFunc~=nil then
				-- minus=skillFunc(self,skillIndex,minus)
			-- end			
		-- end
	-- end	
	if minus>0 then
		doMinusCardHp(bf,self,minus)
	end	
end

function doMinusHpMagic(bf,self,minus)	
	local cardTmp= mTData["card"][self.tid]
	for k=1,3 do
		local passive=package.loaded["logic.battle.passive"]
		if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) then
			local skillTid=cardTmp["skill"..k]
			local skillFunc = passive.befMagicAttackedSkills[skillTid]
			if skillFunc~=nil then
				minus=skillFunc(bf,self,skillIndex,minus)
			end			
		end
	end
	--触发战斗中动态添加的技能
	for k,v in pairs(self.data.buff.addSkill) do
		local skillFunc = passive.befMagicAttackedSkills[v.skillTid]
		if skillFunc~=nil then
			minus=skillFunc(bf,self,v.para,minus)
		end		
	end
	if minus>0 then
		doMinusCardHp(bf,self,minus)
	end	
end

function refresh(card)
	
end


---死亡时数据清理
function doDeadClean(bf,self)
	print("doDeadClean....")
	--清理卡产生的buff
	local cardTmp= mTData["card"][self.tid]
	for skillIndex=1,3 do
		if self.data.buff.target[skillIndex]~=nil then
			for k,v in pairs(self.data.buff.target[skillIndex]) do
				local target=mSelect.selectCardById(bf,self,k)
				if target~=nil then
					local buffList=target.data.buff[v.buffName]
					if buffList~=nil then
						for _,buff in pairs(buffList) do
							if buff.id==v.buffId then
								--如果是是加血buffer
								if buff.buffName=="hp" then
									if target.hp>buff.hpAdd then
										target.hp=target.hp-buff.hpAdd
									else
										target.hp=0
										target.buffHpMinus=target.buffHpMinus+(buff.hpAdd-target.hp)
									end
								end
								buffList[_]=nil
								--table.remove(buffList,_)
								refresh(target)  --清楚buff时刷新状态
							end
						end
					end
				end
			end
		end	
	end	
	
	--数据初始化
	team.inintCardByDead(self)
	
	local team=bf["team"..self.teamId]
	table.insert(team.cemetery,self)
	for k,v in pairs(team.cards) do
		if v==self then
			team.cards[k]=nil
			--table.remove(team.cards,k)
		end
	end
	mView.dieCmd(bf, self)
end


--被杀死
function doDeadByEnemy(bf,self)
	print("doDeadByEnemy....")
	local cardTmp= mTData["card"][self.tid]
	for k=1,3 do
		local passive=package.loaded["logic.battle.passive"]
		if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]~=0 and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0) then
			local skillTid=cardTmp["skill"..k]
			local skillFunc = passive.deadSkills[skillTid]
			if skillFunc~=nil then
				skillFunc(bf, self,k)
			end			
		end
	end	
	doDeadClean(bf,self)	
end

--判断是否存在某技能
function checkSkillExist(self,skillTid)
	local cardTmp= mTData["card"][self.tid]
	for k=1,3 do		
		if cardTmp["skill"..k]~=nil and cardTmp["skill"..k]==skillTid and (self.data.buff.skillBan[k]==nil or self.data.buff.skillBan[k]==0)  then
			return k
		end
	end	
	for k,v in pairs(self.data.buff.addSkill) do
		if v.skillTid==skillTid and v.roundNum~=0 then
			return 0
		end
	end
	return -1
end
--是否可以加debuff
function canDebuff(self)
	if checkSkillExist(self,67)>=1 then
		return false
	end
	return true
end

--是否可以被治疗
function canCure(self)
	if self.data.buff.state[battleType.BATTLE_STATE.NON_CURE] == true then
		return false
	end
	return true
end

function canSkillFighter(self)	
	if self.data.buff.state[battleType.BATTLE_STATE.SEAL] ~=nil then
		return false
	end
	return true
end

function canPhyFighter(self)	
	if self.data.buff.state[battleType.BATTLE_STATE.SEAL] ~=nil or self.data.buff.state[battleType.BATTLE_STATE.SKIP_PHY] ~=nil  or self.data.buff.state[battleType.BATTLE_STATE.PHY_SEAL] ~=nil then
		return false
	end
	return true
end





