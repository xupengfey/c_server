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



function L_onTick( ... )
	assert(false, "xxxxxxxxxxxxxxxxxxxxxx")
end

function L_onRPC( type,jsonArgs )
	-- print("L_onRPC",type,jsonArgs)
	-- print("decode")
	-- printTable(cjson.decode(jsonArgs))
	local funName = table.remove(jsonArgs,1)
	local func
	if type == 1 then
		func = client_rpc_map[funName]
	else
		func = nc_rpc_map[funName]
	end	

	assert(func ~= nil, funName .. " not register")	

	func(unpack(jsonArgs))
	 

	-- print("encode")
	-- local t = {1,2}
	-- print(cjson.encode(t))
end

function L_onMysql( ... )
	-- body
end

C_listen( 7000)

