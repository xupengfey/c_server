local mSys = require "system.sys"
local field=require "logic.battle.field"
mLogin = require "logic.login"

mSys.regClientFunc("login", mLogin.login)
mSys.regClientFunc("createChar", mLogin.createChar)
mSys.regNcFunc("pvePointBattle",field.pvePointBattle)
