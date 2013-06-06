#include "game.h"

extern MYSQL* pmysql;
extern std::deque<char*> db_queue;
extern uv_mutex_t db_queue_mutex;
extern uv_sem_t db_queue_sem;

bool check_args(lua_State* L, int argn)
{
	int n = lua_gettop(L);
	if (argn == n) {
		for(;n>0;n--) {
			if(lua_isnil(L,n)) {
				printf("arg can not be nil\n");
				return false;
			}
		}
		return true;
	} else {
		printf("args count not match, need %d, in fact %d\n", argn, n);
		lua_getglobal(L,lua_cmd_type_name[L_onError]);
		if (lua_pcall(L,0,0,0) == 0) {
		} else {
			lua_pop(L,1);
		}
		return false;
	}
}

int C_senddata(lua_State* L)
{
	if (check_args(L, 3) == false) {
		return 0;
	}
	int sock_id = lua_tointeger(L,1);
	int type = lua_tointeger(L,2);
	const char *json_str = lua_tostring(L,3);
	senddata(sock_id, type, json_str);
	return 0;
}


int C_broadcast(lua_State* L)
{
	if (check_args(L, 3) == false) {
		return 0;
	}
	int type = lua_tointeger(L,2);
	const char *json_str = lua_tostring(L,3);
	int sock_id;
	lua_pushnil(L);  /* first key */
	while (lua_next(L, 1) != 0) {
		sock_id = lua_tointeger(L,-1);
		printf("sock_id=%d\n",sock_id);
		senddata(sock_id, type, json_str);
		lua_pop(L, 1);
	}
	return 0;
}

int C_broadcastall(lua_State* L)
{
	return 0;
}

int C_connect(lua_State* L)
{
	if (check_args(L, 2) == false) {
		return 0;
	}
	const char* ip = lua_tostring(L,1);
	int port = lua_tointeger(L,2);
	int ret = tcp_connect(ip, port);
	return 1;
}

int C_listen(lua_State* L)
{
	if (check_args(L, 1) == false) {
		return 0;
	}
	int port = lua_tointeger(L,1);
	int ret = listen_port(port);
	lua_pushinteger(L,ret);
	return 1;
}

int C_connectmysql(lua_State* L)
{
	if (check_args(L, 5) == false) {
		return 0;
	}
	const char *server = lua_tostring(L,1);
	const char *user = lua_tostring(L,2);
	const char *pass = lua_tostring(L,3);
	const char *database = lua_tostring(L,4);
	int port = lua_tointeger(L,5);

	pmysql = mysql_init(NULL);


   /* Connect to database */
	pmysql = mysql_real_connect(pmysql, server,
         user, pass, database, port, NULL, 0);
	if (pmysql) {
		//mysql_conn_id++;
		//mysql_conn_map[mysql_conn_id] = pmysql;
		lua_pushinteger(L,0);
	} else {
		fprintf(stderr, "%s\n", mysql_error(pmysql));
		lua_pushinteger(L,1);
	}
	return 1;
}




int C_querySync(lua_State* L)
{
	if (check_args(L, 1) == false) {
		return 0;
	}
	return 1;
}

int C_query(lua_State* L)
{
	if (check_args(L, 1) == false) {
		return 0;
	}
	size_t len;
	const char *sql = lua_tolstring(L,1, &len);
	char *new_sql = (char *)malloc(len+1);
	memcpy(new_sql, sql, len+1);
	uv_mutex_lock(&db_queue_mutex);
	db_queue.push_back(new_sql);
	uv_mutex_unlock(&db_queue_mutex);
	uv_sem_post(&db_queue_sem);
	return 1;
}

int C_escapedStr(lua_State* L)
{
	if (check_args(L, 1) == false) {
		return 0;
	}
	size_t len;
	const char *sql = lua_tolstring(L,1,&len);
	char *new_sql = (char*)malloc(len*2);
	size_t new_len = mysql_real_escape_string(pmysql,new_sql,sql,len);
	lua_pushlstring(L,new_sql,new_len);
	free(new_sql);
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
	lua_register(L,"C_escapedStr",		C_escapedStr);
}

