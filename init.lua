printTable = function(root)
	if type(root) ~= "table" then
		return
	end
	local cache = {  [root] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
			else
				table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return table.concat(temp,"\n"..space)
	end
	print(_dump(root, "",""))
end
-- L_onTick L_onRPC L_onMysql
--local json = require "cjson"

client_rpc_map = {}
nc_rpc_map = {}

-- rpc_map = {{},{}}

function L_onError(message)
	print("[Error]+++++++++++++++++++++++++++++++++++++++")
	print(message)
	print(debug.traceback())
	--print(message)
	print("[Error]---------------------------------------\n")

end

function L_onTick( ... )
end

function L_onRPC( type,jsonArgs )
	--print("L_onRPC",type,jsonArgs)
	-- print("decode")
	-- printTable(cjson.decode(jsonArgs))
	local args = cjson.decode(jsonArgs)
	local funName = table.remove(args,1)
	print("L_onRPC", funName)
	local t = {"aa'aa","bbbbbb\"bbb","ccc.ccc",{"dddddddddd"}}
	t.tt = t
	local str = cjson.encode(t)
	-- local func
	-- if type == 1 then
	-- 	func = client_rpc_map[funName]
	-- else
	-- 	func = nc_rpc_map[funName]
	-- end	

	-- assert(func ~= nil, funName .. " not register")	

	-- func(unpack(args))
	 

	-- print("encode")
	-- local t = {1,2}
	-- print(cjson.encode(t))
end

function L_onConnectedNC( sockId)
	print("L_onConnectedNC",sockId)
	local t = {"funName","aaaaaa","bbbbbbbbbb"}
	local str = cjson.encode(t)
	print(str)
	-- C_senddata(sockId,2,str)
	-- C_senddata(sockId,2,str)
	-- C_senddata(sockId,2,str)
end

function L_onMysql( ret )
	print("L_onMysql", tostring(ret))
	printTable(ret)
	--assert(false)
end

C_listen( 7000)
-- print("lua start")

--C_connect("192.168.0.13",8080)

C_senddata(1,2,"aaaaaaa")

print("C_connectmysql",C_connectmysql("192.168.0.31","root","31^FishTest31@","test",3306))
--_query("show databases")
-- C_query("select 1")
-- C_query("select 0.00001")
-- C_query("select sum(id) from t_account")
-- local t = {"aa'aa","bbbbbb\"bbb","ccc.ccc",{"dddddddddd"}}
-- t.tt = t
-- local str = cjson.encode(t)
-- local sql = "insert test (json) values ('"..C_escapedStr(str).."')"
-- C_query(sql)
-- local sql = "select * from test"
local sql = "select * from test"
C_query(sql)

function L_decode( str )
	print("L_decode",str)
	return cjson.decode(str)
	-- return {"funName","aaaaaa","bbbbbbbbbb"}
	-- return cjson.decode(str)
end


function L_onCommand( str )
	print("L_onCommand",str)
	local func = loadstring(str)
	func()
end
