--encoding=utf-8
-----------------------------------------------------------------------------
--| Table相关的一些处理
-----------------------------------------------------------------------------
--[[
local table = require "table"
local string = require "string"
local print,setmetatable,type,pairs,tostring,next,getmetatable = print,setmetatable,type,pairs,tostring,next,getmetatable
]]--

--module("common.util.tableutil")

-- 深层拷贝一个table
cloneTable = function (object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end
--浅拷贝一个table
--只copy table的第一层 而不是递归的copy
shallowCloneTable = function (object)
	local res = {}
	for k,v in pairs(object) do
		res[k] = object[k]
	end
	return res
end
	--树桩打印Table
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



-- function printLines(tt,space)
-- 	local spacestr = ""
-- 	local msg = ""
-- 	if space >0 then
-- 		for i=1,space do
-- 			spacestr = spacestr.." ";
-- 		end
-- 	end
-- 	for i,v in pairs(tt) do
-- 		if type(i)==type(1) then
-- 			msg = msg..spacestr.."["..i.."]="
-- 		else
-- 			msg = msg..spacestr..i.."="
-- 		end
-- 		if type(v) == type({}) then
-- 			local tab = printLines(v,space+4)
-- 			local count = 0
-- 			for i,v in pairs(v) do
-- 				count =count +1;
-- 				break;
-- 			end
-- 			if count >0 then
-- 				msg = msg .."{\n"
-- 				msg = msg..tab
-- 				msg = msg..spacestr.."},"
-- 			else
-- 				msg = msg.."{},"
-- 			end
-- 		else
-- 			if type(v)==type("") then
-- 				msg = msg..'"'..v..'",';
-- 			else
-- 				msg = msg..v..",";
-- 			end
-- 		end
-- 		msg = msg.."\n"
--     end
--     return msg

-- end
-- oldPrintTable = printTable
-- printTable = function(t)
-- 	local msg = printLines(t,4)
-- 	print("table = {\n"..msg.."}\n")
-- end
	
getTableSize = function( t )
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count
end

