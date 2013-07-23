
-- local pairs,os,math,next,table,cjson,print,type,printTable,tostring
--     = pairs,os,math,next,table,cjson,print,type,printTable,tostring
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mChar = require "logic.character"
local mObject = require "logic.object"
local mIndexdata = require "logic.indexdata"
local gData = require "template.gamedata".data
local mCard = require "logic.card"
local mMagic = require "logic.magic"


module ("logic.team",package.seeall)


function createCreatureTeam( creatureTpl)
	print("createCreatureTeam##############",creatureTpl)
	-- printTable(creatureTpl)
	local heroTpl = gData.hero[creatureTpl.heroLv]
	-- print(creatureTpl.heroLv)
	-- printTable(gData.hero)
	-- print(type(heroTpl))
	-- printTable(heroTpl)
	local team = {
		id = creatureTpl.heroId,
		capacity = 0,
		lv = creatureTpl.heroLv,
		cardList = {},
		hero = {hp = heroTpl.hp, magicList={}}
	}
	

	if type(creatureTpl.cardData) ~= "table" then
		creatureTpl.cardData = splitString(creatureTpl.cardData, "|")
	end	
	if type(creatureTpl.magicData) ~= "table" then
		creatureTpl.magicData = splitString(creatureTpl.magicData, "|")
	end	

	for k,v in pairs(creatureTpl.cardData) do
		local lvAndId
		if type(v) == type("") then
			lvAndId = splitString(v,":")
			creatureTpl.cardData[k] = lvAndId
		else
			lvAndId = v
		end	

		local lv = tonumber(lvAndId[1])
		local tid = tonumber(lvAndId[2])
		print(">>>>>>>>>>>>>>>>>>>>>>>>>")
		-- printTable(lvAndId)
		if #lvAndId < 3 then
			local cardTpl = gData.card[tid]
			-- printTable(cardTpl)
			lvAndId[3] = cardTpl.hp0 + lv*cardTpl.hpPerAdd
			lvAndId[4] = cardTpl.atk0 + lv*cardTpl.atkPerAdd
		end	
		local card = {
			id = k,
			hp = lvAndId[3],
			atk = lvAndId[4],
			tid = tid,
			cardLv = lv,
		}
		table.insert(team.cardList, card)

	end	

	for k,v in pairs(creatureTpl.magicData) do
		local lvAndId
		if type(v) == type("") then
			lvAndId = splitString(v,":")
			creatureTpl.magicData[k] = lvAndId
		else
			lvAndId = v
		end	
		local magic = {
			id = k,
			charId = creatureTpl.heroId,
			index = k,
			tid = tonumber(lvAndId[2]),
			skillLv = tonumber(lvAndId[1]),
		}
		table.insert(team.hero.magicList, magic)

	end	
	printTable(team)
	return team
end


function  createCharTeam( char )
	local heroTpl = gData.hero[char.data.lv]
	local team = {
		id = char.data.id,
		capacity = 0,
		lv = char.data.lv,
		cardList = mCard.getBattleCards(char.data.id),
		hero = {hp = heroTpl.hp, magicList=mMagic.getMagicUsedList(char.sockId)}
	}
	return team
end



