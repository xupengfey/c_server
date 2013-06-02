#ifndef _GAME_H_
#define _GAME_H_

#ifdef WIN32
#pragma comment(lib, "lua51.lib")
#pragma comment (lib, "libuv.lib")
#pragma comment (lib, "ws2_32.lib")
#pragma comment(lib, "psapi.lib")
#pragma comment(lib, "Iphlpapi.lib")
#endif

#include <stdio.h>
#include <uv/uv.h>
#include <lua/lua.hpp>
#include <deque>
#include <map>

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
static lua_State* L;
static uv_mutex_t lua_mutex;

static std::deque<char*> rpc_queue;
static uv_mutex_t rpc_queue_mutex;

static std::deque<char*> db_queue;
static uv_mutex_t db_queue_mutex;


static std::map<int, Sock*> client_map;
static uv_rwlock_t client_map_rwlock;

//static int sock_id;
//static uv_mutex_t sock_id_mutex;

void call_luafunction(char *funcname, int argn, void *data);
void sendData(int sock_id, int type, const char* str);
#endif
