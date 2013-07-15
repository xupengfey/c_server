local pairs,os,math,next,table,cjson
	= pairs,os,math,next,table,cjson
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mLogin = require "logic.login"

mLogin.login(1,{accName='x1'})