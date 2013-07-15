local assert,math,print,pairs,table,printTable = assert,math,print,pairs,table,printTable
local actionType = require("logic.constants.ActionType")
module ("logic.battle.view")

function pushAction(bf,cmd)
	if bf.playList[bf.roundNum]==nil then
		bf.playList[bf.roundNum]={}
	end
	table.insert(bf.playList[bf.roundNum], cmd)
end

--攻击
function phyAttackCmd(bf, self, target)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.PHY_ATTACK
	cmd.cardId = self.id
	if target ~= nil then
		cmd.targetCardId = target.id
	else 
		cmd.targetCardId = 0
	end
	pushAction(bf, cmd)
end

--群攻
function phyGroupAttackCmd(bf, self, targetCol)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.GROUP_PHY_ATTACK
	cmd.cardId = self.id
	cmd.targetCardArr = {}
	if targetCol ~= nil then
		for k, v in pairs(targetCol) do
			table.insert(cmd.targetCardArr, v.id)
		end
	end
	pushAction(bf, cmd)
end

--法攻
function magicAttackCmd(bf,self,target,skillId)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.MAGIC_ATTACK
	if self~=nil then
		cmd.cardId = self.id
	else	
		cmd.cardId = 0
	end	
	cmd.skillId=skillId
	if target ~= nil then
		cmd.targetCardId = target.id
	else 
		cmd.targetCardId = 0
	end
	pushAction(bf, cmd)
end

--法群攻
function magicGroupAttackCmd(bf, self, targetCol,skillId)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.GROUP_MAGIC_ATTACK
	if self~=nil then
		cmd.cardId = self.id
	else	
		cmd.cardId = 0
	end	
	cmd.skillId=skillId
	cmd.targetCardArr = {}
	if targetCol ~= nil then
		for k, v in pairs(targetCol) do
			table.insert(cmd.targetCardArr, v.id)
		end
	end
	pushAction(bf, cmd)
end


--
function hpChangeCmd(bf, self, value)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.HP_CHANGE
	if self~=nil then
		cmd.cardId = self.id
	else	
		cmd.cardId=0
	end	
	cmd.value = value	
	pushAction(bf,cmd)
end

--
function atkChangeCmd(bf, self, value)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.ATK_CHANGE
	cmd.cardId = self.id
	cmd.value = value	
	pushAction(bf,cmd)
end

function atkChangeOnceCmd(bf, self, value)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.ATK_CHANGE_ONCE
	cmd.cardId = self.id
	cmd.value = value	
	pushAction(bf,cmd)
end

--死亡
function dieCmd(bf, self)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.DEAD
	cmd.cardId = self.id
	pushAction(bf,cmd)
end

function addStateBuffCmd(bf, self, status,roundNum)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.ADD_STATUS
	cmd.cardId = self.id
	cmd.status =status
	cmd.roundNum=roundNum
	pushAction(bf, cmd)
end

function addDeBuffCmd(bf, self, skillId,num)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.ADD_DEBUFF
	cmd.cardId = self.id
	cmd.skillId =skillId
	cmd.num =num
	pushAction(bf, cmd)
end

function removeDeBuffCmd(bf, self, skillId)
	local cmd = {}
	cmd.type = actionType.ACTION_TYPE.REMOVE_DEBUFF
	cmd.cardId = self.id
	cmd.skillId = skillId
	pushAction(bf, cmd)
end

