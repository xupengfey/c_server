local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mGameData = require "template.gamedata"

module ("logic.indexdata",package.seeall)

-- 多重索引数据 启动时初始化

data = {}


-- 最多支持3重索引
local config = {
	citycell = {"cityId", "cellId","hardLevel"},
	citycell_creature = {"cityId", "cellId"},
}

function generateIndexData()
	print("generateIndexData")
	for tableName,v in pairs(config) do
		local tableData = mGameData.data[tableName]

		local tmp = {}
		for _,line in pairs(tableData) do
			if tmp[line[v[1]]] == nil then
				tmp[line[v[1]]] = {}
			end	

			if v[2] ~= nil then
				if tmp[line[v[1]]][line[v[2]]] == nil then
					tmp[line[v[1]]][line[v[2]]] = {}
				end

				if v[3] ~= nil then
					if tmp[line[v[1]]][line[v[2]]][line[v[3]]] == nil then
						tmp[line[v[1]]][line[v[2]]][line[v[3]]] = {}
					end
					table.insert(tmp[line[v[1]]][line[v[2]]][line[v[3]]],line)
				else
					table.insert(tmp[line[v[1]]][line[v[2]]],line)		 
				end
			else
				table.insert(tmp[line[v[1]]],line)	
			end

				
		end 
		data[tableName] = tmp

	end

	-- printTable(data)		
end





generateIndexData()