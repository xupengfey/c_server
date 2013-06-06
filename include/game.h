#ifndef _GAME_H_
#define _GAME_H_

#ifdef WIN32
#pragma comment(lib, "mysqlclient.lib")
//#pragma comment(lib, "libmysql.lib")
#pragma comment(lib, "lua51.lib")
#pragma comment (lib, "libuv.lib")
#pragma comment (lib, "ws2_32.lib")
#pragma comment(lib, "psapi.lib")
#pragma comment(lib, "Iphlpapi.lib")
#endif


#include <deque>
#include <map>
#include <stdio.h>
#include <assert.h>
#include <uv/uv.h>

extern "C" {
	#include <mysql.h>
	#include "lua/lua.h"
	#include "lua/lualib.h"
	#include "lua/lauxlib.h"
}
#include "cjson/cjson.h"
int json_decode(lua_State *l);
int luaopen_cjson(lua_State *l);


#ifdef WIN32
#define uv_sleep(timeout) Sleep(timeout)
#else
#define uv_sleep(timeout) usleep(timeout*1000)
#endif



typedef enum {
	L_onError,
    L_onTick,
    L_onRPC,
	L_decode,
	L_onConnected,
	L_onConnectedNC,
	L_onClose,
	L_onCloseNC,
    L_onMysql,
	L_onCloseMysql
} lua_cmd_type_t;

static const char *lua_cmd_type_name[] = {
	"L_onError",
	"L_onTick",
    "L_onRPC",
	"L_decode",
	"L_onConnected",
	"L_onConnectedNC",
	"L_onClose",
	"L_onCloseNC",
    "L_onMysql",
	"L_onCloseMysql",
    NULL
};



typedef struct _Sock {
	int sock_id;
	int read_status; // 0包头 5个字节 | 1 内容 | 2 finish
	int lenth;
	int readed;
	char protocol; // 0 json 1 amf3    01 加密类型 23 压缩类型 4567协议类型
	char* buff;
	uv_tcp_t* handle;

}Sock,*PSock;

//static MYSQL* pmysql;
//static lua_State* L;
//static uv_mutex_t lua_mutex;
//
//static std::deque<std::pair<int, char*> > rpc_queue;
//static uv_mutex_t rpc_queue_mutex;
//
//std::deque<char*> db_queue;
//static uv_mutex_t db_queue_mutex;
//
//
//static std::map<uv_tcp_t*, Sock*> client_map;
//static std::map<int, Sock*> c_sockid_map;
//static uv_rwlock_t client_map_rwlock;
//static int c_sock_id;
//static uv_mutex_t c_sock_id_mutex;
//
//static std::map<uv_tcp_t*, Sock*> nc_map;
//static std::map<int, Sock*> nc_sockid_map;
//static uv_rwlock_t nc_map_rwlock;
//static int nc_sock_id;
//static uv_mutex_t nc_sock_id_mutex;

//MYSQL mysql;


uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size);
void read_client_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void read_nc_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void do_read(int type,uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void call_luafunction(char *funcname, int argn, void *data);
void on_new_connection(uv_stream_t *server, int status);

void senddata(int sock_id, int type, const char* str);
int listen_port(int port);
int tcp_connect(const char* ip, int port);

void call_luarpc(int type, char* json_cmd);

void registerAPI(lua_State* L);

int json_decode(lua_State *l);
int luaopen_cjson(lua_State *l);

#endif
