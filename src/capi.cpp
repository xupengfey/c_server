#include "game.h"

int C_sendData(lua_State* L)
{
	int arg_cnt = lua_gettop(L);
	int sock_id = lua_tonumber(L,1);
	int type = lua_tonumber(L,2);
	const char *json_str = lua_tostring(L,3);
	sendData(sock_id, type, json_str);
	return 0;
}

void registerAPI(lua_State* L)
{
	lua_register(L,"C_sendData",		C_sendData);
}

