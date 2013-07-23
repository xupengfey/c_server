local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"


module "logic.object"

function set( char,key,value )
	char.data[key] = value
	char.dirty[key] = true
end

