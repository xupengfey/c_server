#ifndef _GAME_H_
#define _GAME_H_

#ifdef _WIN32
#pragma comment(lib, "mysqlclient.lib")
#pragma comment(lib, "lua51.lib")
#pragma comment (lib, "libuv.lib")
#pragma comment (lib, "ws2_32.lib")
#pragma comment(lib, "psapi.lib")
#pragma comment(lib, "Iphlpapi.lib")
#pragma comment(lib, "libglog_static.lib")
#pragma comment(lib, "libtcmalloc_minimal-debug.lib")

#define GOOGLE_GLOG_DLL_DECL
#define GLOG_NO_ABBREVIATED_SEVERITIES
#endif


#include <iostream>
//#include <stdio.h>
#include <assert.h>
#include "stdlib.h"
#include "string.h"
#include <uv/uv.h>
#include "cjson/cjson.h"
#include <glog/logging.h>
#include <vector>
#include <queue>
#include <map>



extern "C" {
	#include <mysql.h>
	#include "lua/lua.h"
	#include "lua/lualib.h"
	#include "lua/lauxlib.h"
}


using namespace std;


#ifdef _WIN32
#define uv_sleep(timeout) Sleep(timeout)
#else
#define uv_sleep(timeout) usleep(timeout*1000)
#endif

#ifdef _WIN32
#include <direct.h>
#include <io.h>
#else
#include <stdarg.h>
#include <sys/stat.h>
#endif

#ifdef _WIN32
#define ACCESS _access
#define MKDIR(a) _mkdir((a))
#define MYLOG(level) cout
#else
#define ACCESS access
#define MKDIR(a) mkdir((a),0755)
#define MYLOG(level) LOG(level)
#endif



typedef enum {
	L_onError,
    L_onTick,
    L_onRPC,
	L_encode,
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
	"L_encode",
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
	char* buff;
	uv_tcp_t* handle;

}Sock,*PSock;


typedef struct _RpcQueBuff {
	char protocol; // 0 json 1 amf3    01 加密类型 23 压缩类型 4567协议类型
	int dest_type;
	int sock_id;
	int data_len;
	char *data;
}RpcQueBuff,*PRpcQueBuff;

typedef struct _SendQueBuff {
	int dest_type; // 1 客户端 2 服务端
	int *psock; //NULL 全部广播  psock[0] 表示数量
	char *data;
	int data_len;
}SendQueBuff,*PSendQueBuff;

typedef struct _SendDataBuff {
	int num;
	uv_buf_t* puv_buf;
}SendDataBuff,*PSendDataBuff;




uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size);
void read_client_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void read_nc_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void do_read(int type,uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void call_luafunction(char *funcname, int argn, void *data);
void on_new_connection(uv_stream_t *server, int status);

void senddata(int sock_id, int type, const char* str);
int listen_port(int port);
int tcp_connect(const char* ip, int port);

//void call_luarpc(int type, char* json_cmd);
void iencrypt(char *str, int len);
void unencrypt(char *str, int len);
char* compress(char *str);
char* uncompress(char *str);
void json_encode(lua_State* L);
void json_decode(lua_State* L, char*str, int len);



void registerAPI(lua_State* L);

int json_decode(lua_State *l);
int luaopen_cjson(lua_State *l);

#endif
