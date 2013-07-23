module("logic.battle.data")

battleFieldList = {}
count = 0

function addBattle(bf, callback, params)
	count = count + 1
	bf.id = count
	battleFieldList[bf.id] = {bf=bf, callback=callback, params=params}
end

function removeBattle(id)
	battleFieldList[id] = nil
end

function getBattle( bfid )
	return battleFieldList[bfid]
end

function getBattleBf(bfid)
	return battleFieldList[bfid].bf
end
