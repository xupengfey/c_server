
extern "C" {
	#include "lua_cjson/cjson.h";
	int json_decode(lua_State *l);
	//int lua_cjson_new(lua_State *l);
	//int luaopen_cjson(lua_State *l);
	//int luaopen_cjson_safe(lua_State *l);
	int luaopen_cjson(lua_State *l);
};



