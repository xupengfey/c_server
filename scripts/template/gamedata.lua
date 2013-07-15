

local _G,pairs,print,setmetatable,assert,tonumber,printTable 
	= _G,pairs,print,setmetatable,assert,tonumber,printTable

local gameTemplate = require ("template.data.gametemplate")


local dataIndexConf = {}


dataIndexConf[1] = require ("template.dataindex1conf")
dataIndexConf[2] = require ("template.dataindex2conf")
dataIndexConf[3] = require ("template.dataindex3conf")




--后续模板表会变成只读接口
module("template.gamedata")



local INDEX_LIST = {1,2,3} --索引列表

local DataIndex = {        --索引数据
				[1] = {},
				[2] = {},
				[3] = {},
            }

--外部访问的模板数据库
data = {}

setmetatable(data,{__index = gameTemplate})



function checkIndex(id)
	if (tonumber(id) ~= 1) and (tonumber(id) ~= 2) and (tonumber(id) ~= 3)
	then
		assert(false,"invalid index id")
	end
end

--为单个表创建索引
--tableName
function createSingleTableIndex(tableName,index,keyName)
	local idx = tonumber(index)
    
	checkIndex(index)
	DataIndex[idx][tableName] = {} --每次都是新建,更新整个表的这个键值的索引
	
	
	local tab = gameTemplate[tableName] --没有对应的游戏表格
	if tab == nil then
		return
	end
	
	for id, obj in pairs(tab) do
		local value = obj[keyName]
		if value == nil then
			assert(false,"fatal error ,keyName " .. keyName .. " in table " .. tableName .. " does not exist")
		end
		if DataIndex[idx][tableName][value] == nil then
			DataIndex[idx][tableName][value] = {}
		end
		if tableName == "quest_finishnpc" then
		end
		DataIndex[idx][tableName][value][obj.id] = obj
	end

end


function createDataIndex(id)
	local dataIndexConfig = dataIndexConf[tonumber(id)]
	for key,value in pairs(dataIndexConfig)
	do
		if value ~= nil then
			createSingleTableIndex(key,tonumber(id),value)
		end
	end
end

function createAllIndex()
	for k,v in pairs(INDEX_LIST)
	do
		createDataIndex(v)
	end
end





--这里返回的集合如果可以被修改很可能会引发潜在的问题
--
--只返回有索引的
function getIndexedData(tableName,fieldName,fieldValue)

	for _,id in pairs(INDEX_LIST) do
		
		if dataIndexConf[tonumber(id)][tableName] == fieldName then
			local res =  DataIndex[id][tableName][fieldValue]


			if res == nil then
				res = {}
			end
			return res
		end
	end
	print (tableName .. " : " .. fieldName .. " is not indexed")
	assert(false)
	return {}
end







