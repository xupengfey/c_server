-- local pairs,os,math,next,table,cjson
	-- = pairs,os,math,next,table,cjson
-- local mSys = require "system.sys"
-- local mTimer = require "system.timer"
-- local mConfig = require "config"
-- local mLogin = require "logic.login"


-- mLogin.login(1,{accName='x2'})
local field =  require ("logic.battle.field")
local mChar=require"logic.character"
local battleData=require("logic.battle.data")
local attackData={}
attackData.id=1
attackData.capacity=1
attackData.lv=10
attackData.hero={}
attackData.hero.hp=100000
local magic={}
magic.id=1
magic.charId=1
magic.index=1
magic.tid=1
magic.skillLv=2
attackData.hero.magicList={}
--table.insert(attackData.hero.magicList,magic)
attackData.cardList={}
local card1={}
card1.id=11111
card1.hp=20000
card1.atk=5000
card1.tid=5
card1.cardLv=11
table.insert(attackData.cardList,card1)
local card3={}
card3.id=11112
card3.hp=10000
card3.atk=5000
card3.tid=5
card3.cardLv=11
table.insert(attackData.cardList,card3)
local defendData={}
defendData.id=2
defendData.capacity=2
defendData.lv=20
defendData.hero={}
defendData.hero.hp=200000
defendData.hero.magicList={}
defendData.cardList={}
local card2={}
card2.id=21111
card2.hp=20000
card2.atk=4000
card2.tid=1
card2.cardLv=12
table.insert(defendData.cardList,card2)
local card4={}
card4.id=21112
card4.hp=20000
card4.atk=4000
card4.tid=1
card4.cardLv=12
table.insert(defendData.cardList,card4)
-- local bf=field.pvePointBattle(attackData, defendData,0)
-- battleData.addBattle(bf)

local char={}
char.sockId=1
char.data={}
char.data.id=1
char.data.accName="accName"
char.data.charName="charName"
mChar.loginData(char)

-- local char2=mChar.getCharBySocket(1)
-- char2.data.battleId=bf.id
-- field.battleAuto(1)

print("#############33")
printTable(attackData)

print("#############33")
printTable(defendData)
-- printTable(bf)