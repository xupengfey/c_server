local print,next,printTable,pairs,C_ClientCall,math,cloneTable = print,next,printTable,pairs,C_ClientCall,math,cloneTable
local mTData = require("template.gamedata").data
local battleType = require("logic.constants.BattleType")
local mView = require("logic.battle.View")
module("logic.battle.buff")

function getBuffUseTime(buffId)
	local buff = mTData.buff[buffId]
	return buff.useTime
end

function haveSameBuff(self, buffId)
	if self.buff[buffId] ~= nil then	
		return true
	end
	return false
end

function haveSameCodeBuff(self, buffId)
	return false
end

function addShortBuff(bf, self, buffId, values)
	local buffTmp = mTData.buff[buffId]
	if buffTmp.type == 2 and self.prop.zhen ~= nil then
		return
	end
	if self.status ~= battleType.TEAM_MEM_STATUS.ALIVE then
		return
	end
	if haveSameBuff(self, buffId) == true then
		return
	end
	
	if haveSameCodeBuff(self, buffId) == true then
		return
	end
	
	pureAddShortBuff(bf, self, buffId, values)
	
end

--清除 除晕眩外的所有buff
function removeAbnBuff(bf, self)
	for i, v in pairs(self.buff) do
		local buffTmp = mTData.buff[i]
		if buffTmp.state == battleType.BATTLE_STATE.SKILL_DISABLE or buffTmp.state == battleType.BATTLE_STATE.FREEZE or 
			buffTmp.state == battleType.BATTLE_STATE.BURNING or buffTmp.state == battleType.BATTLE_STATE.BAN_TREAT_INSPIRE or
			buffTmp.state == battleType.BATTLE_STATE.BURN_FOOD or buffTmp.state == battleType.BATTLE_STATE.MUDDY then
			removeShortBuff(bf, self, i)
		end
	end
end

function removeShortBuff(bf, self, buffId)
	--print("removeBuff")
	self.buff[buffId] = nil
	if mTData.buff[buffId].display == 1 then
		mView.removeBuffCmd(bf, self, buffId)
	end
	refreshShortState(self)
	computeProp(self, buffId, -1)
end

--values {timeAdd=1, dotVal=2,moraleVal=3,}
function constructBuff(buffId, values)
	local useTime = getBuffUseTime(buffId)
	local buff = {}
	buff.remain = useTime
	if values ~= nil then
		for k, v in pairs(values) do
			buff[k] = v
		end
	end
	if buff["timeAdd"] ~= nil then
		buff.remain = buff.remain + buff["timeAdd"]
		buff["timeAdd"] = nil
	end
	return buff
end

function refreshShortState(self)
	self.state = {}
	for i, v in pairs(self.buff) do
		local buffTmp = mTData.buff[i]
		self.state[buffTmp.state] = true
	end
end

function pureAddShortBuff(bf, self, buffId, values)
	--print("addBuff")
	self.buff[buffId] = constructBuff(buffId, values)
	if buffId == 28 then self.prop.pofuchenzhou = true end
	if buffId == 29 then self.prop.yiqidangqian = true end
	if buffId == 30 then self.prop.xuezhanbafang = true end
	if mTData.buff[buffId].display == 1 then
		mView.addBuffCmd(bf, self, buffId)
	end
	refreshShortState(self)
	computeProp(self, buffId, 1)
end

function computeProp(self, buffId, flag)
	local buffTmp = mTData.buff[buffId]
	for k = 1, 6 do
		if buffTmp["prop"..k] ~= nil and buffTmp["prop"..k] ~= "" then
			self.data[buffTmp["prop"..k]] = self.data[buffTmp["prop"..k]] + flag*buffTmp["propNum"..k]
		end
	end
end