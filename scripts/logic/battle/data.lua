module("logic.battle.data")

battleFieldList = {}
count = 0

function addBattle(bf)
	battleFieldList[bf.id] = bf
	count = count + 1
end

function removeBattle(id)
	battleFieldList[id] = nil
end

function getBattle(bfid)
	return battleFieldList[bfid]
end
