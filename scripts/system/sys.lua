
local client_rpc_map = client_rpc_map
local nc_rpc_map = nc_rpc_map	

module ("system.sys",package.seeall)

function regClientFunc( funcName,func )
	client_rpc_map[funcName] = func
end

function regNcFunc( funcName,func )
	nc_rpc_map[funcName] = func
end


function callClient(sockId, funcName, ...)
	return C_senddata(sockId, 1, {funcName,...})
end

function callNc(sockId, funcName, ...)
	return C_senddata(sockId, 2, {funcName,...})
end

-- sockList
-- 	{sockId,-}
function broadCastToSockList( sockList,  funcName, ...)
	return C_broadcast(sockList, 1, {funcName,...})
end

function broadcastToAll( funcName, ... )
	return C_broadcastall(1, {funcName,...})
end

-- 异步
function connect( ip,sockId )
	return C_connect(ip,sockId)
end

function listen( port )
	return C_listen(port)
end


-- return 0 success 1 failed
function dbConnect( server,user,pass,database,port )
	return C_connectmysql(server,user,pass,database,port)
end

-- 异步
function dbQuery( sql,cb,... )
	assert(type(cb) == type(dbQuery))
	table.insert(cbFunc, {func=cb,params={...}})
	return C_query(sql)
end

function escapedStr( str )
	return C_escapedstr(str)
end

function log( level,msg )
	C_log(level,msg)
end
