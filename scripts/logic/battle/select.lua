local type,assert,math,table,pairs,print,tonumber,cloneTable,printTable = type,assert,math,table,pairs,print,tonumber,cloneTable,printTable
local mTData = require("template.gamedata").data
module("logic.battle.select")


function oppositeTeam(bf,self)
	local targetTeamId = 1
	if self.teamId == 1 then
		targetTeamId = 2
	end
	return bf["team"..targetTeamId]
end

--对方位置的卡牌
function selectTarget(bf, self)
	local targetTeamId = 1
	if self.teamId == 1 then
		targetTeamId = 2
	end
	local index=-1
	for i,v in pairs(bf["team"..self.teamId].cards) do
		if v == self then
			index=i			
		end
	end
	assert(index ~= -1)
	if bf["team"..targetTeamId].cards[index]~=nil then
		return bf["team"..targetTeamId].cards[index]
	end	
	return nil
end

function selectTargetIndex(bf, self)
	local index=-1
	for i,v in pairs(bf["team"..self.teamId].cards) do
		if v == self then
			index=i			
		end
	end	
	return  index
end

--选择除了self的所有类型的card
function selectKindExpectOne(bf, self,kind)
	local list={}
	for i,v in pairs(bf["team"..self.teamId].cards) do
		if v ~= self and mTData["card"][v.tid].kind==kind then
			table.insert(list,v)
		end
	end
	return list
end

--选择相同tid的卡牌
function selectSameTargetList(bf,self)
	local list={}
	for i,v in pairs(bf["team"..self.teamId].cards) do
		if v ~= self and v.tid==self.tid then
			table.insert(list,v)
		end
	end
	return list
end

--选择血量最少的n个card
function selectLessHpList(bf,teamId,num)	
	local list={}
	for index=1,num do
		list[index]={}
		list[index].hp=100000000
	end
	for i,v in pairs(bf["team"..teamId].cards) do
		for index=num,1,-1 do
			if list[index].hp>v.hp then
				list[index+1]=list[index]
			else
				list[index+1]=v
				break
			end
		end
	end
	for index=num,1,-1 do
		if list[index].hp==100000000 then
			list[index]=nil
		else
			break
		end	
	end
	return list
end

function getOppoLessHpList(bf,self,num)
	local teamId = 1
	if self.teamId == 1 then
		teamId = 2
	end
	return selectLessHpList(bf,teamId,num)
end

--随即选择个n卡牌
function selectRandomCards(bf,teamId,num)
	local list={}
	local indexList={}
	for i=1,#bf["team"..teamId].cards do
		table.insert(indexList,i)
	end
	for i=1,num do
		if #indexList<=0 then
			break
		end	
		local index=math.random(1,#indexList)
		table.insert(list,bf["team"..teamId].cards[index])
		table.remove(indexList,index)
	end	
	return list
end

function selectOppoRandomCards(bf,self,num)
	local teamId = 1
	if self.teamId == 1 then
		teamId = 2
	end
	return selectRandomCards(bf,teamId,num)
end

--选择本方除了self的随即n张卡牌
function selectExpectRandomCards(bf,self,num)
	local list={}
	local indexList={}
	for i=1,#bf["team"..self.teamId].cards do
		if bf["team"..self.teamId].cards[i]~=self then
			table.insert(indexList,i)
		end	
	end
	for i=1,num do
		if #indexList<=0 then
			break
		end	
		local index=math.random(1,#indexList)
		table.insert(list,bf["team"..teamId].cards[index])
		table.remove(indexList,index)
	end	
	return list
end

function selectCardById(bf,self,id)
	local teamId=self.teamId
	for k,v in pairs(bf["team"..teamId].cards) do
		if v.id==id then
			return v			
		end
	end
	for k,v in pairs(oppositeTeam(bf,self).cards) do
		if v.id==id then
			return v			
		end
	end
	return nil
end