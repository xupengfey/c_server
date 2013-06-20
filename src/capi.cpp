#include "game.h"

extern MYSQL* pmysql;
extern std::queue<char*> db_queue;
extern uv_mutex_t db_queue_mutex;
extern uv_sem_t db_queue_sem;

extern std::queue<SendQueBuff* > send_queue;
extern uv_mutex_t send_queue_mutex;
extern uv_sem_t send_queue_sem;

extern uv_async_t async;

bool check_args(lua_State* L, int argn)
{
	int n = lua_gettop(L);
	if (argn == n) {
		for(;n>0;n--) {
			if(lua_isnil(L,n)) {
				MYLOG(ERROR) << "arg can not be nil" << endl;
				return false;
			}
		}
		return true;
	} else {
		MYLOG(ERROR) << "args count not match, need " << argn << ", in fact %" << n;
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
	int dest_type = lua_tointeger(L,2);
	size_t data_len;
	json_encode(L);
	const char *json_str = lua_tolstring(L,3,&data_len);

	SendQueBuff* buf = (SendQueBuff*)calloc(sizeof(SendQueBuff),1);
	buf->dest_type = dest_type;
	buf->data = (char *)malloc(data_len);
	buf->data_len = data_len;
	buf->psock = (int *)malloc(2*sizeof(int));
	buf->psock[0] = 1;
	buf->psock[1] = sock_id;
	memcpy(buf->data, json_str, data_len);
	uv_mutex_lock(&send_queue_mutex);
	send_queue.push(buf);
	uv_mutex_unlock(&send_queue_mutex);
	uv_sem_post(&send_queue_sem);
	uv_async_send(&async);
	//sendHandler();
	return 0;
}


int C_broadcast(lua_State* L)
{
	if (check_args(L, 3) == false) {
		return 0;
	}
	int dest_type = lua_tointeger(L,2);
	json_encode(L);
	size_t data_len;
	const char *json_str = lua_tolstring(L,3,&data_len);
	int sock_id;
	

	SendQueBuff* buf = (SendQueBuff*)calloc(sizeof(SendQueBuff),1);
	buf->dest_type = dest_type;
	buf->data = (char *)malloc(data_len);
	buf->data_len = data_len;
	buf->psock = (int*)malloc(1024*sizeof(int));
	int count = 0;
	lua_pushnil(L);  /* first key */
	while (lua_next(L, 1) != 0) {
		sock_id = lua_tointeger(L,-1);
		if (count < 1023) {
			count++;
			buf->psock[count] = sock_id;
		}
		lua_pop(L, 1);
	}
	buf->psock[0] = count;
	uv_mutex_lock(&send_queue_mutex);
	send_queue.push(buf);
	uv_mutex_unlock(&send_queue_mutex);
	uv_sem_post(&send_queue_sem);
	return 0;
}

int C_broadcastall(lua_State* L)
{
	if (check_args(L, 2) == false) {
		return 0;
	}
	int dest_type = lua_tointeger(L,1);
	json_encode(L);
	size_t data_len;
	const char *json_str = lua_tolstring(L,2,&data_len);
	SendQueBuff* buf = (SendQueBuff*)calloc(sizeof(SendQueBuff),1);
	buf->dest_type = dest_type;
	buf->data = (char *)malloc(data_len);
	buf->data_len = data_len;
	uv_mutex_lock(&send_queue_mutex);
	send_queue.push(buf);
	uv_mutex_unlock(&send_queue_mutex);
	uv_sem_post(&send_queue_sem);
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
		lua_pushinteger(L,0);
	} else {
		MYLOG(ERROR) << mysql_error(pmysql) << endl;
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
	db_queue.push(new_sql);
	uv_mutex_unlock(&db_queue_mutex);
	uv_sem_post(&db_queue_sem);
	return 1;
}

int C_escapedstr(lua_State* L)
{
	if (check_args(L, 1) == false) {
		return 0;
	}
	size_t len;
	const char *json_str = lua_tolstring(L,1,&len);
	char *new_str = (char*)malloc(len*2);
	size_t new_len = mysql_real_escape_string(pmysql,new_str,json_str,len);
	lua_pushlstring(L,new_str,new_len);
	free(new_str);
	return 1;
}

int C_log(lua_State* L)
{
	if (check_args(L, 2) == false) {
		return 0;
	}
	int log_level = lua_tointeger(L,1);
	const char* log_info = lua_tostring(L, 2);
	switch(log_level) {
		case 0:
			MYLOG(INFO) << log_info << endl;
			break;
		case 1:
			MYLOG(WARNING) << log_info << endl;
			break;
		case 2:
			MYLOG(ERROR) << log_info << endl;
			break;
		default:
			MYLOG(ERROR) << log_info << endl;
			break;
	}
	return 0;
}

int C_close(lua_State* L)
{
	if (check_args(L, 2) == false) {
		return 0;
	}
	int type = lua_tointeger(L,1);
	int sock_id = lua_tointeger(L,2);
	closeSocket(type, sock_id);
	return 0;
}

// encode and compress
int C_transfer(lua_State* L)
{
	if (check_args(L, 1) == false) {
		return 0;
	}	
	size_t data_len;
	json_encode(L);
	const char *json_str = lua_tolstring(L,1,&data_len);
	char *new_str = (char*)malloc(data_len*2);
	if (!new_str) {
		return 1;
	}


	size_t new_len = mysql_real_escape_string(pmysql,new_str,json_str,data_len);

	size_t destLen = compressBound(new_len); 
		char *dest = (char *)malloc(destLen + 8);
		//*(uLong*)dest = sourceLen;
		//int ret;

		//int ret = compress((Bytef *)dest+1, &destLen, (Bytef *)new_str, new_len);
		//if (ret == Z_OK) {
		//	lua_pushlstring(lua_vm, dest, destLen+8);
		//} else {
		//	LOG(ERROR) << "compress error " << ret;
		//	lua_pushnil(lua_vm);
		//}
		//delete[] dest;


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
	lua_register(L,"C_escapedstr",		C_escapedstr);
	lua_register(L,"C_log",		C_log);
	lua_register(L,"C_close",		C_close);
}

