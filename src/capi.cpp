#include "game.h"

int C_senddata(lua_State* L)
{
	int arg_cnt = lua_gettop(L);
	int sock_id = lua_tonumber(L,1);
	int type = lua_tonumber(L,2);
	const char *json_str = lua_tostring(L,3);
	senddata(sock_id, type, json_str);
	return 0;
}


int C_broadcast(lua_State* L)
{
	return 0;
}

int C_broadcastall(lua_State* L)
{
	return 0;
}

int C_connect(lua_State* L)
{
	return 1;
}

int C_listen(lua_State* L)
{
	//const char* ip = lua_tostring(L,1);
	int port = lua_tonumber(L,1);
	int ret = listen_port(port);
	lua_pushinteger(L,ret);
	return 1;
}

int C_connectmysql(lua_State* L)
{
	return 1;
}

int C_query(lua_State* L)
{
	return 1;
}


void registerAPI(lua_State* L)
{
	lua_register(L,"C_senddata",		C_senddata);
	lua_register(L,"C_broadcast",		C_broadcast);
	lua_register(L,"C_broadcastall",		C_broadcastall);
	lua_register(L,"C_connect",		C_connect);
	lua_register(L,"C_listen",		C_listen);
	lua_register(L,"C_connectmysql",		C_connectmysql);
	lua_register(L,"C_query",		C_query);
}

