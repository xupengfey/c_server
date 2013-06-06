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
#include "cjson/cjson.h"

extern "C" {
	#include <mysql.h>
	#include "lua/lua.h"
	#include "lua/lualib.h"
	#include "lua/lauxlib.h"
}




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
	L_onCloseMysql,
	L_onCommand
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
	"L_onCommand",
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
