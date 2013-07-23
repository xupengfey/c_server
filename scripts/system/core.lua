local mTimer = require "system.timer"
require "util.table"
require "util.string"

INFO = 0
WARNING = 1
ERROR = 2


-- printTable = function(root)
-- 	if type(root) ~= "table" then
-- 		return
-- 	end
-- 	local cache = {  [root] = "." }
-- 	local function _dump(t,space,name)
-- 		local temp = {}
-- 		for k,v in pairs(t) do
-- 			local key = tostring(k)
-- 			if cache[v] then
-- 				table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
-- 			elseif type(v) == "table" then
-- 				local new_key = name .. "." .. key
-- 				cache[v] = new_key
-- 				table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
-- 			else
-- 				table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
-- 			end
-- 		end
-- 		return table.concat(temp,"\n"..space)
-- 	end
-- 	print(_dump(root, "",""))
-- end
-- L_onTick L_onRPC L_onMysql
--local json = require "cjson"

client_rpc_map = {}
nc_rpc_map = {}
cbFunc = {}


function L_onError(message)
	C_log(ERROR,"[Error]+++++++++++++++++++++++++++++++++++++++")
	C_log(ERROR,message)
	C_log(ERROR,debug.traceback())
	C_log(ERROR,"[Error]---------------------------------------\n")
end

function L_onTick( ... )
	-- print("L_onTick")
	mTimer.runTimer()
end

function L_onRPC( type,sockId,args )
	print("L_onRPC",type,sockId,args)
	-- printTable(args)
	local funName = table.remove(args,1)
	print("rpc func name", funName)
	local func
	if type == 1 then
		func = client_rpc_map[funName]
	else
		func = nc_rpc_map[funName]
	end	
	if func ~= nil then
		func(sockId, unpack(args))
	else	
		print(funName .. " not register")
	end	

	
end

function L_onConnected( sockId)
	print("L_onConnected",sockId)
end
function L_onClose( sockId )
	print("L_onClose",sockId)
	local mLogin = package.loaded["logic.login"]
	mLogin.logout(sockId)
end
function L_onConnectedNC( sockId)
	print("L_onConnectedNC",sockId)
end
function L_onCloseNC( sockId)
	print("L_onCloseNC",sockId)
end

function L_onMysql( ret )
	print("L_onMysql", tostring(ret))
	local cbEntry = table.remove(cbFunc, 1)
	cbEntry.func(ret, unpack(cbEntry.params))
end
function L_onCloseMysql( sockId)
	print("L_onCloseMysql",sockId)
end

function L_encode( t )
	return cjson.encode(t)
end
function L_decode( str )
	return cjson.decode(str)
end

function L_onCommand( cmd,file )
	print("L_onCommand",cmd,file)
	if file == "" then
		file = "hotfix.lua"
	end	
	print("hotfix file",file)
	if cmd == "load" then
		dofile(file)
	end	
	-- f = loadstring(str)
	-- f()
end



