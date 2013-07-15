local assert,math,print,pairs,table,math,tonumber,printTable= assert,math,print,pairs,table,math,tonumber,printTable

local mView = require ("logic.battle.view")
local EventType = require ("logic.constants.EventType")
local mTData = require("template.gamedata").data
local skill =require "logic.battle.skill"
local mSelect =require "logic.battle.select"
local cardMgr=require "logic.battle.cardMgr"
local battleType = require ("logic.constants.BattleType")
module ("logic.battle.heroSkill")

heroSkills={}

function checkHelloSkillEnable(bf,hero,magic)
	local magicTemp=mTData["magic"][magic.tid]
	print("checkHelloSkillEnable roundNum "..bf.roundNum.." event "..magicTemp.event)
	local targetTeamId = 1
	if hero.teamId == 1 then
		targetTeamId = 2
	end
	if magicTemp.triggerNum>magic.triggerNum then
		if magicTemp.event==EventType.HERO_EVENT.hpLessThanEvt then
			if checkIsHpLessThan(hero,tonumber(magicTemp.triggerPara)) then
				trigger(bf,hero,magic)
			end			
		elseif magicTemp.event==EventType.HERO_EVENT.roundNumEvt then
			if bf.roundNum==tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end			
		elseif magicTemp.event==EventType.HERO_EVENT.sfCardNumEvt then
			if #bf["team"..hero.teamId].cards>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.sfPropCardNumEvt then
			if #getTeamPropNum(bf["team"..hero.teamId].cards,magicTemp.kind)==tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.sfDeadCardNumEvt then
			if #bf["team"..hero.teamId].cemetery>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.sfPropDeadCardNumEvt then
			if #getTeamPropNum(bf["team"..hero.teamId].cemetery,magicTemp.kind)>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.tarCardNumEvt then
			if #bf["team"..targetTeamId].cards>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.tarPropCardNumEvt then
			if #getTeamPropNum(bf["team"..targetTeamId].cards,magicTemp.kind)>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.tarDeadCardNumEvt then
			if #bf["team"..targetTeamId].cemetery>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		elseif magicTemp.event==EventType.HERO_EVENT.tarPropDeadCardNumEvt then
			if #getTeamPropNum(bf["team"..targetTeamId].cemetery,magicTemp.kind)>=tonumber(magicTemp.triggerPara) then
				trigger(bf,hero,magic)
			end	
		end
	end	
end

function getTeamPropNum(cardList,prop)
	local num=0
	for k,v in pairs(cardList) do
		if v.kind==prop then
			num=num+1
		end	
	end
	return num
end
function trigger(bf,hero,magic)
	local magicTemp=mTData["magic"][magic.tid]
	local skillTid=magicTemp.skillId
	local skillFunc = heroSkills[skillTid]
	if skillFunc~=nil then
		skillFunc(bf,hero,magic)
	end	
	magic.triggerNum =magic.triggerNum +1
end

function checkIsHpLessThan(hero,para)	
	if hero.hp/hero.hpTotal<=para/100 then
		return true
	end
	return false
end



function getAbsParaAdd(skillTid,skillLv)
	local p=tonumber(mTData["skill"][skillTid]["para"..skillLv])
	print("p "..p)
	return p
end

--法宝-落雷
heroSkills[76] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,1)
	if  #targetList>0 then
		local act=targetList[1]
		local minusHp=getAbsParaAdd(76,magic.skillLv)
		mView.magicAttackCmd(bf,nil,act,76)
		cardMgr.doMinusHpMagic(bf,act,minusHp)	
		if math.random(1,100)<50 then
			mView.addStateBuffCmd(bf,act,battleType.BATTLE_STATE.PHY_SEAL,1)
			skill.addStateBuffBySkillLv(act,battleType.BATTLE_STATE.PHY_SEAL,1,76,magic.skillLv)
		end
	end	
end

--法宝-连环闪电
heroSkills[77] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,3)
	local paras=mTData["skill"][77]["para"..magic.skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, nil, targetList,77)
		for k,v in pairs(targetList) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)	
			if math.random(1,100)<tonumber(paraList[2]) then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.PHY_SEAL,1)
				skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.PHY_SEAL,1,77,magic.skillLv)
			end
		end	
	end	
end

--法宝-雷暴
heroSkills[78] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local minusHp=getAbsParaAdd(78,magic.skillLv)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,78)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)	
			if math.random(1,100)<35 then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.PHY_SEAL,1)
				skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.PHY_SEAL,1,78,magic.skillLv)
			end
		end	
	end	
end

--法宝-冰弹
heroSkills[79] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,1)
	if  #targetList>0 then
		local target=targetList[1]
		local minusHp=getAbsParaAdd(79,magic.skillLv)
		mView.magicAttackCmd(bf,nil,target,79)
		cardMgr.doMinusHpMagic(bf,target,minusHp)	
		local rd=math.random(1,100)
		if rd<45 then
			mView.addStateBuffCmd(bf,target,battleType.BATTLE_STATE.SEAL,1)
			skill.addStateBuffBySkillLv(target,battleType.BATTLE_STATE.SEAL,1,79,magic.skillLv)
		end	
	end	
end

--法宝-霜冻新星
heroSkills[80] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,3)
	local skillLv=magic.skillLv
	local paras=mTData["skill"][80]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, nil, targetList,80)
		for k,v in pairs(targetList) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)				
			if math.random(1,100)<tonumber(paraList[2]) then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.SEAL,1)
				skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.SEAL,1,80,skillLv)
			end
		end		
	end	
end

--法宝-暴风雪
heroSkills[81] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local minusHp=getAbsParaAdd(81,magic.skillLv)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,81)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)	
			if math.random(1,100)<30 then
				mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.SEAL,1)
				skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.SEAL,1,81,magic.skillLv)
			end
		end	
	end	
end


--法宝-火球
heroSkills[82] = function (bf, hero,magic)	
	local targetList = mSelect.selectOppoRandomCards(bf, hero,1)
	if  #targetList>0 then
		local target=targetList[1]
		local paras=mTData["skill"][82]["para"..magic.skillLv]
		local paraList = splitWithTrim(paras, ",")
		local minMinus=tonumber(paraList[1])
		local maxMinus=tonumber(paraList[2])
		minusHp=math.random(minMinus,maxMinus)
		mView.magicAttackCmd(bf,nil,target,82)
		cardMgr.doMinusHpMagic(bf,target,minusHp)						
	end	
end


--法宝-火墙
heroSkills[83] = function (bf, hero,magic)	
	local targetList = mSelect.selectOppoRandomCards(bf, hero,3)
	local skillLv=magic.skillLv
	local paras=mTData["skill"][83]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minMinus=tonumber(paraList[1])
	local maxMinus=tonumber(paraList[2])
	minusHp=math.random(minMinus,maxMinus)
	if #targetList>0 then
		mView.magicGroupAttackCmd(bf, nil, targetList,83)
		for k,v in pairs(targetList) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)					
		end	
	end	
end

--法宝-烈焰风暴
heroSkills[84] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local skillLv=magic.skillLv
	local paras=mTData["skill"][54]["para"..skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minMinus=tonumber(paraList[1])
	local maxMinus=tonumber(paraList[2])
	minusHp=math.random(minMinus,maxMinus)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,84)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)					
		end	
	end	
end


--法宝-烈火焚神
heroSkills[85] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local buffNum=getAbsParaAdd(81,magic.skillLv)
	mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,85)
	for k,v in pairs(oppoTeam.cards) do
		local buff=skill.checkBuffBySkillLv(v.data.buff.hpDebuff,85,magic.skillLv)
		if buff~=nil then
		else
			if cardMgr.canDebuff(v) then
				mView.addDeBuffCmd(bf, v, 85,buffNum)
				addHpDeBuffBySkillLv(v,-buffNum,-1,85,magic.skillLv)				
			end	
		end
	end
end

--法宝-天罡战气
heroSkills[86] = function (bf, hero,magic)
	local num=getAbsParaAdd(86,magic.skillLv)
	local targetList=bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,86)
	for k,v in pairs(targetList) do
		mView.atkChangeOnceCmd(bf, v, num)
		skill.addAtkBuffBySkillLv(v,num,1,86,magic.skillLv)
	end
end

--群体嗜血
heroSkills[87] = function (bf, hero,magic)
	local num=getAbsParaAdd(87,magic.skillLv)
	local targetList=bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,87)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,87,num)
		--mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.BLOOD_SUCK,-1)
		--skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.BLOOD_SUCK,-1,87,magic.skillLv,num)
	end
end

--法宝-吸血
heroSkills[88] = function (bf, hero,magic)
	local num=getAbsParaAdd(88,magic.skillLv)
	local targetList = mSelect.selectRandomCards(bf, hero.teamId,1)
	if  #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf,nil,target,88)						
		skill.addSkillBuff(target,-1,88,num)
		--mView.addStateBuffCmd(bf,target,battleType.BATTLE_STATE.BLOOD_ABSORB,-1)
		--skill.addStateBuffBySkillLv(target,battleType.BATTLE_STATE.BLOOD_ABSORB,-1,88,magic.skillLv,num)
	end	
end

--法宝-群体嗜血 (添加技能和吸血一样88)
heroSkills[89] = function (bf, hero,magic)
	local num=getAbsParaAdd(89,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,89)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,88,num)
		--mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.BLOOD_ABSORB,-1)
		--skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.BLOOD_ABSORB,-1,89,magic.skillLv,num)
	end	
end

--群体狂热
heroSkills[90] = function (bf, hero,magic)
	local num=getAbsParaAdd(89,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,90)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,90,num)
		--mView.addStateBuffCmd(bf,v,battleType.BATTLE_STATE.RABIT,-1)
		--skill.addStateBuffBySkillLv(v,battleType.BATTLE_STATE.RABIT,-1,90,magic.skillLv,num)
	end	
end

--法宝-狙击
heroSkills[91] = function (bf, hero,magic)
	local num=getAbsParaAdd(91,magic.skillLv)
	local targetList = mSelect.selectRandomCards(bf, hero.teamId,1)
	if  #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf,nil,target,91)						
		skill.addSkillBuff(target,-1,91,num)		
	end	
end

--法宝-二重狙击
heroSkills[92] = function (bf, hero,magic)
	local num=getAbsParaAdd(92,magic.skillLv)
	local targetList = mSelect.selectRandomCards(bf, hero.teamId,1)
	if  #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf,nil,target,92)						
		skill.addSkillBuff(target,-1,92,num)		
	end	
end

--法宝-群体狙击 (添加技能和狙击一样91)
heroSkills[93] = function (bf, hero,magic)
	local num=getAbsParaAdd(93,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,93)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,91,num)		
	end		
end

--法宝-群体战意
heroSkills[94] = function (bf, hero,magic)
	local num=getAbsParaAdd(94,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,94)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,94,num)		
	end		
end

--法宝-群体反击
heroSkills[95] = function (bf, hero,magic)
	local num=getAbsParaAdd(95,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,95)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,95,num)		
	end		
end

--法宝-治疗
heroSkills[96] = function (bf, hero,magic)
	local num=getAbsParaAdd(96,magic.skillLv)
	local targetList=mSelect.selectLessHpList(bf,hero.teamId,1)
	if  #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf,nil,target,96)						
		cardMgr.doAddCardHp(bf,target,num)		
	end	
end

--法宝-群体回春
heroSkills[97] = function (bf, hero,magic)
	local num=getAbsParaAdd(97,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,97)
	for k,v in pairstargetList(targetList) do
		skill.addSkillBuff(v,1,97,num)		
	end	
end


--法宝-甘霖
heroSkills[98] = function (bf, hero,magic)
	local num=getAbsParaAdd(98,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,98)
	for k,v in pairs(targetList) do
		cardMgr.doAddCardHp(bf,v,num)	
	end	
end

--法宝-祈祷
heroSkills[99] = function (bf, hero,magic)
	local num=getAbsParaAdd(99,magic.skillLv)
	mView.magicGroupAttackCmd(bf, nil, nil,99)
	local team=bf["team"..hero.teamId]
	cardMgr.doAddHeroHp(bf,team,num)		
end

--法宝-天劫
heroSkills[100] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local minusHp=getAbsParaAdd(100,magic.skillLv)
	if #oppoTeam.cards>0 then
		mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,100)
		for k,v in pairs(oppoTeam.cards) do
			cardMgr.doMinusHpMagic(bf,v,minusHp)				
		end	
	end	
end

--法宝-诅咒
heroSkills[101] = function (bf, hero,magic)
	local minusHp=getAbsParaAdd(101,magic.skillLv)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	mView.magicAttackCmd(bf, nil, nil,101)
	cardMgr.doMinusHeroHp(bf,oppoTeam,minusHp)		
end

--法宝-时空逆流
heroSkills[102] = function (bf, hero,magic)
	local num=getAbsParaAdd(102,magic.skillLv)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local targetList=selectOppoRandomCards(bf,hero,1)
	if #targetList>0 then
		local act=targetList[1]
		mView.magicAttackCmd(bf, nil, act,102)
		if math.random(1,100)<num then
			cardMgr.doDeadClean(act)
			table.insert(oppoTeam.cardList,act)				
		end
	end
end

--法宝-群体闪避
heroSkills[103] = function (bf, hero,magic)
	local num=getAbsParaAdd(103,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,103)
	for k,v in pairst(targetList) do
		skill.addSkillBuff(v,1,103,num)		
	end	
end


--法宝-毒液
heroSkills[104] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,1)
	local paras=mTData["skill"][104]["para"..magic.skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	local buffNum=tonumber(paraList[2])

	if #targetList>0 then
		local target=targetList[1]

		mView.magicAttackCmd(bf,nil,target,104)
		cardMgr.doMinusHpMagic(bf,target,minusHp)		
		local buff=skill.checkBuffBySkillLv(target.data.buff.hpDebuff,104,magic.skillLv)
		if buff~=nil then
		else
			if cardMgr.canDebuff(target) then
				mView.addDeBuffCmd(bf, target, 104,buffNum)
				skill.addHpDeBuffBySkillLv(target,-buffNum,-1,104,magic.skillLv)
			end	
		end
	end
end
	
--法宝-毒雾
heroSkills[105] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,3)
	local paras=mTData["skill"][105]["para"..magic.skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	local buffNum=tonumber(paraList[2])
	mView.magicGroupAttackCmd(bf, nil, targetList,105)
	for k,v in pairs(targetList) do
		cardMgr.doMinusHpMagic(bf,v,minusHp)		
		local buff=skill.checkBuffBySkillLv(v.data.buff.hpDebuff,105,magic.skillLv)
		if buff~=nil then
		else
			if cardMgr.canDebuff(target) then
				mView.addDeBuffCmd(bf, v, 105,buffNum)
				skill.addHpDeBuffBySkillLv(v,-buffNum,-1,105,magic.skillLv)
			end	
		end
	end
end

--法宝-万毒追魂
heroSkills[106] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local paras=mTData["skill"][106]["para"..magic.skillLv]
	local paraList = splitWithTrim(paras, ",")
	local minusHp=tonumber(paraList[1])
	local buffNum=tonumber(paraList[2])
	mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,106)
	for k,v in pairs(oppoTeam.cards) do
		cardMgr.doMinusHpMagic(bf,v,minusHp)		
		local buff=skill.checkBuffBySkillLv(v.data.buff.hpDebuff,106,magic.skillLv)
		if buff~=nil then
		else
			if cardMgr.canDebuff(target) then
				mView.addDeBuffCmd(bf, v, 106,buffNum)
				skill.addHpDeBuffBySkillLv(v,-buffNum,-1,106,magic.skillLv)
			end	
		end
	end
end


--法宝-削弱
heroSkills[107] = function (bf, hero,magic)
	local targetList = mSelect.selectOppoRandomCards(bf, hero,1)
	local num=getAbsParaAdd(107,magic.skillLv)
	if #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf,nil,target,107)

		local buff=checkBuffBySkillLv(target.data.buff.atkDebuff,107,magic.skillLv)
		mView.atkChangeCmd(bf, target, -num)
		if buff~=nil then
			buff.atkAdd=buff.atkAdd-num
		else
			addAtkBuffBySkillLv(target,-num,-1,107,magic.skillLv)
		end
	end
end

--法宝-群体削弱
heroSkills[108] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local num=getAbsParaAdd(108,magic.skillLv)
	mView.magicGroupAttackCmd(bf, nil, oppoTeam.cards,108)
	for k,v in pairs(oppoTeam.cards) do
		local buff=checkBuffBySkillLv(v.data.buff.atkDebuff,108,magic.skillLv)
		mView.atkChangeCmd(bf, v, -num)
		if buff~=nil then
			buff.atkAdd=buff.atkAdd-num
		else
			addAtkBuffBySkillLv(v,-num,-1,108,magic.skillLv)
		end
	end
end

--法宝-群体盾刺
heroSkills[109] = function (bf, hero,magic)
	local num=getAbsParaAdd(109,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,109)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,109,num)		
	end		
end


--法宝-群体穷追猛打
heroSkills[110] = function (bf, hero,magic)
	local num=getAbsParaAdd(110,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,110)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,110,num)		
	end		
end


--法宝-群体自爆
heroSkills[111] = function (bf, hero,magic)
	local num=getAbsParaAdd(111,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,111)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,111,num)		
	end		
end

--法宝-阎王印
heroSkills[112] = function (bf, hero,magic)
	local oppoTeam=mSelect.oppositeTeam(bf, hero)
	local minusHp=getAbsParaAdd(112,magic.skillLv)
	mView.magicAttackCmd(bf,nil,nil,112)	
	cardMgr.doMinusHeroHp(bf,oppoTeam,minusHp)

	local targetList=mSelect.selectOppoRandomCards(bf,hero,1)
	if #targetList>0 then
		local target=targetList[1]
		cardMgr.doDeadByEnemy(bf,target)
		table.insert(oppoTeam.cemetery,target)			
	end		
end

--法宝-玄武盾
heroSkills[113] = function (bf, hero,magic)
	local num=getAbsParaAdd(113,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,113)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,113,num)		
	end	
end

--法宝-护心镜
heroSkills[114] = function (bf, hero,magic)
	local targetList=mSelect.selectRandomCards(bf,hero.teamId,1)
	local num=getAbsParaAdd(114,magic.skillLv)
	if #targetList>0 then
		local target=targetList[1]
		mView.magicAttackCmd(bf, nil, target,114)
		skill.addSkillBuff(v,1,114,num)			
	end
end

--法宝-群体岩甲  (添加的技能和护心镜一样114)
heroSkills[115] = function (bf, hero,magic)
	local num=getAbsParaAdd(115,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,115)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,1,114,num)		
	end	
end


--法宝-群体魔甲 
heroSkills[116] = function (bf, hero,magic)
	local num=getAbsParaAdd(116,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,116)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,116,num)		
	end	
end

--法宝-群体反射
heroSkills[117] = function (bf, hero,magic)
	local num=getAbsParaAdd(117,magic.skillLv)
	local targetList =bf["team"..hero.teamId].cards
	mView.magicGroupAttackCmd(bf, nil, targetList,117)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,117,num)		
	end	
end


--法宝-天眼通 (添加的技能68)
heroSkills[118] = function (bf, hero,magic)
	local num=getAbsParaAdd(118,magic.skillLv)
	local targetList=mSelect.selectRandomCards(bf,hero.teamId,num)
	mView.magicGroupAttackCmd(bf, nil, targetList,118)
	for k,v in pairs(targetList) do
		skill.addSkillBuff(v,-1,68)		
	end	
end

--法宝-天塌地陷
heroSkills[119] = function (bf, hero,magic)
	local num=getAbsParaAdd(119,magic.skillLv)
	local targetList=mSelect.selectOppoRandomCards(bf,hero,1)
	if #targetList>0 and math.random(1,100)<num then
		local target=targetList[1]
		mView.magicAttackCmd(bf, nil, target,119)
		if cardMgr.checkSkillExist(target,68)==-1 then
			mView.addStateBuffCmd(bf,target,battleType.BATTLE_STATE.SEAL,1)
			skill.addStateBuffBySkillLv(target,battleType.BATTLE_STATE.SEAL,1,119,magic.skillLv)
		else
			mView.magicAttackCmd(bf,target,target,119)	
		end		
	end
end


--法宝-魂归来兮
heroSkills[120] = function (bf, hero,magic)
	local num=getAbsParaAdd(120,magic.skillLv)
	if math.random(1,100)<num then
		mView.magicAttackCmd(bf, nil, nil,120)
		for k,v in pairs(bf["team"..hero.teamId].cemetery) do
			if (v.skill1~=nil and v.skill1==49) or (v.skill2~=nil and v.skill2==49) or (v.skill3~=nil and v.skill3==49) then
			else
				if #bf["team"..hero.teamId].cards<10 then
					table.insert(bf["team"..hero.teamId].cards,v)
				else
					table.insert(bf["team"..hero.teamId].canditate,v)
				end
				table.remove(bf["team"..hero.teamId].cemetery,k)
				break
			end
		end	
	end
end


