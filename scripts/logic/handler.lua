local mSys = require "system.sys"
local field=require "logic.battle.field"
local mLogin = require "logic.login"
local mCitywar=require "logic.citywar"
local card=require "logic.card"
local magic=require "logic.magic"

mSys.regClientFunc("login", mLogin.login)
mSys.regClientFunc("createChar", mLogin.createChar)
mSys.regClientFunc("fightCell", mCitywar.fightCell)
-- mSys.regNcFunc("pvePointBattle",field.pvePointBattle)
mSys.regClientFunc("testCell", mCitywar.testCell)

mSys.regClientFunc("addCardToBattle", field.addCardToBattle)
mSys.regClientFunc("removeCardFromBattle", field.removeCardFromBattle)
mSys.regClientFunc("battleOneRound", field.battleOneRound)
mSys.regClientFunc("battleAuto", field.battleAuto)

mSys.regClientFunc("cardUpgrade", card.cardUpgrade)
mSys.regClientFunc("sellCard", card.sellCard)
mSys.regClientFunc("updateGoupCard", card.updateGoupCard)
mSys.regClientFunc("setUsedGid", card.setUsedGid)

mSys.regClientFunc("wearMagic", magic.wearMagic)
mSys.regClientFunc("removeMagic", magic.removeMagic)
mSys.regClientFunc("magicMove", magic.magicMove)
mSys.regClientFunc("magicUpgrade", magic.magicUpgrade)
mSys.regClientFunc("sellMagic", magic.sellMagic)

