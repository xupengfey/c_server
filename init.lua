-- requie "scripts/system/core"

-- C_listen( 7000)
-- print("lua start")

--C_connect("192.168.0.13",8080)

-- print("C_connectmysql",C_connectmysql("192.168.0.31","root","31^FishTest31@","test",3306))
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
-- local sql = "select NULL"
-- C_query(sql)
-- if C_SetClientSendCompress ~= nil then
-- 	package.cpath = "../lib/?.so;../lib/luasocket/?.so;../server/lib/?.so;../server/lib/luasocket/?.so"
-- else
-- 	package.cpath = "../lib/?.dll;../lib/luasocket/?.dll"
-- end
package.path = "scripts/?.lua;"

print("load init.lua")
require "system.core"
local sys = require "system.sys"

-- printTable(_G)
print("C_connectmysql",sys.dbConnect("192.168.0.31","root","31^FishTest31@","test",3306))
local sql = "select * from test"
sys.dbQuery(sql,function ( ret )
	print("cb called")
	printTable(ret)
end)

C_broadcast({[1]=1,[2]=2,[3]=3},2,"bbbb")
