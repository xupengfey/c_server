#ifndef _GAME_H_
#define _GAME_H_

#ifdef WIN32
#pragma comment(lib, "lua51.lib")
#pragma comment (lib, "libuv.lib")
#pragma comment (lib, "ws2_32.lib")
#pragma comment(lib, "psapi.lib")
#pragma comment(lib, "Iphlpapi.lib")
#endif

#include <lua/lua.hpp>
//#include "lua/lua.h"
//#include "lua/lualib.h"
//#include "lua/lauxlib.h"
#include <deque>
#include <map>
#include <stdio.h>
#include <uv/uv.h>
#include <lua_cjson/cjson.hpp>







typedef enum {
    L_onTick,
    L_onRPC,
    L_onMysql
} lua_cmd_type_t;

static const char *lua_cmd_type_name[] = {
	"L_onTick",
    "L_onRPC",
    "L_onMysql",
    NULL
};



typedef struct _Sock {
	int sock_id;
	int read_status; // 0包头 5个字节 | 1 内容 | 2 finish
	int lenth;
	int readed;
	bool encripted;
	bool compressed;
	int protocol; // 0 json 1 amf3
	char* buff;
	uv_tcp_t* handle;

}Sock,*PSock;


static uv_loop_t* loop;
static uv_tcp_t tcp_server;
static lua_State* L;
static uv_mutex_t lua_mutex;

static std::deque<std::pair<int, char*>> rpc_queue;
static uv_mutex_t rpc_queue_mutex;

static std::deque<char*> db_queue;
static uv_mutex_t db_queue_mutex;


static std::map<int, Sock*> client_map;
static uv_rwlock_t client_map_rwlock;

static std::map<int, Sock*> nc_map;
static uv_rwlock_t nc_map_rwlock;

//static int sock_id;
//static uv_mutex_t sock_id_mutex;
uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size);
void read_client_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void read_nc_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void do_read(int type,uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void call_luafunction(char *funcname, int argn, void *data);
void senddata(int sock_id, int type, const char* str);
int listen_port(int port);


void call_luarpc(int type, char* json_cmd);

void registerAPI(lua_State* L);



#endif
