//#pragma comment (lib, "libuv.lib")
//#pragma comment (lib, "ws2_32.lib")
//#pragma comment(lib, "psapi.lib")
//#pragma comment(lib, "Iphlpapi.lib")
#include "game.h"


static uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size) {
	return uv_buf_init((char *)malloc(suggested_size), suggested_size);
}

void on_close(uv_handle_t* peer) {
  free(peer);
}

static void after_read(uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {
	printf("after read %d\n", nread);
	uv_tcp_t* client = (uv_tcp_t*)handle;
	printf("after_read sock=%d\n", client->socket);
	//write_req_t *wr;
	uv_shutdown_t* req = NULL;
	Sock *sock = NULL;
	if (nread < 0) {
		/* Error or EOF */
		//ASSERT (uv_last_error(loop).code == UV_EOF);
		goto DEL;
		//if (buf.base) {
		//	free(buf.base);
		//}

		//req = (uv_shutdown_t*) malloc(sizeof *req);
		//uv_shutdown(req, handle, after_shutdown);
		//return;
	}

	if (nread == 0) {
		/* Everything OK, but nothing read. */
		free(buf.base);
		return;
	}
	
	uv_rwlock_rdlock(&client_map_rwlock);
	if (client_map.find(client->socket) != client_map.end()) {
		sock = client_map[client->socket];
	}
	uv_rwlock_rdunlock(&client_map_rwlock);
	if (sock == NULL) {
		return;
	}

	int len = 0;
	int i = 0;
	while(i < nread) {
		switch(sock->read_status) {
		case 0:
			if (sock->readed == 0) {
				sock->lenth = 0;
			}
			for (;i<nread;i++){
				if (sock->readed < 4) {
					sock->readed++;
					printf("%d: %d: %c\n",i,(unsigned char)buf.base[i],buf.base[i]);
					sock->lenth = (sock->lenth << 8) + (unsigned char)(buf.base[i]);
				} else  {
					printf("##head end len=%d\n",sock->lenth);
					sock->readed = 0;
					sock->buff = (char*)malloc(sock->lenth+1); // '\0
					sock->read_status = 1;
					break;
				} 
			}

			if (sock->lenth > 1000000 ) {
				printf("data too large error sock=%d\n", sock->sock_id);
				goto DEL;
			}

			if (i == nread) {
				free(buf.base);
				return;
			}
		case 1:
			len = min(sock->lenth-sock->readed, nread-i);
			if (len > 0) {
				memcpy(sock->buff+sock->readed, buf.base+i, len);
				sock->readed += len;
				i += len;
			}
			if (sock->readed == sock->lenth) {
				sock->buff[sock->lenth] = '\0';
				sock->read_status = 2;
			} else {
				free(buf.base);
				return;
			}
		case 2:
			int first = sock->buff[0];
			if (first & (1<<7) == (1<<7)) {
				sock->encripted = true;	
			} else {
				sock->encripted = false;
			}
			if (first & (1<<6) == (1<<6)) {
				sock->compressed = true;	
			} else {
				sock->compressed = false;
			}
			sock->protocol = first % (1<<6);

			if (sock->encripted) {
			}

			if (sock->compressed) {
			}
			//printf("fubll package %s",sock->buff);

			sock->read_status = 0;
			sock->readed = 0;
			uv_mutex_lock(&rpc_queue_mutex);
			rpc_queue.push_back(sock->buff+1);
			uv_mutex_unlock(&rpc_queue_mutex);
		}
	}

DEL:
	if (buf.base) {
		free(buf.base);
	}
	if (sock) {
		uv_rwlock_rdlock(&client_map_rwlock);
		client_map.erase(sock->sock_id);
		uv_rwlock_rdunlock(&client_map_rwlock);
		if (sock->buff) {
			free(sock->buff);
		}
		free(sock);
	}
	uv_close((uv_handle_t*)handle, on_close);

	

		//uv_rwlock_rdlock(&numlock);

		//Sock *sock = 
		//if (buf.base[i] == 'Q') {
		//if (i + 1 < nread && buf.base[i + 1] == 'S') {
		//	free(buf.base);
		//	uv_close((uv_handle_t*)handle, on_close);
		//	return;
		//} else {
		//	uv_close(server, on_server_close);
		//	server_closed = 1;
		//}


		//extern cJSON *cJSON_Parse(const char *value);
	//}
}

void after_send(uv_write_t* req, int status){
	free(req);
}

void sendData(int sock_id, int type, const char* str){
	Sock* sock = NULL;
	uv_rwlock_rdlock(&client_map_rwlock);
	sock = client_map[sock_id];
	uv_rwlock_rdunlock(&client_map_rwlock);
	if (sock) {
		uv_write_t* req = (uv_write_t*) malloc(sizeof(uv_write_t));
		uv_buf_t buf = uv_buf_init((char*)str, strlen(str));
		if (uv_write(req, (uv_stream_t*)sock->handle, &buf, 1, after_send)) {
			printf("[Error] uv_write failed");	
		}
	}

}



void on_new_connection(uv_stream_t *server, int status) {
    if (status == -1) {
        // error!
        return;
    }

    uv_tcp_t *client = (uv_tcp_t*) malloc(sizeof(uv_tcp_t));
    uv_tcp_init(loop, client);
    if (uv_accept(server, (uv_stream_t*) client) == 0) {
		Sock* new_sock = (Sock*)malloc(sizeof(Sock));
		memset(new_sock,0,sizeof(*new_sock));
		new_sock->sock_id = client->socket;
		new_sock->handle = client;
		new_sock->read_status = 0;
		new_sock->readed = 0;
		uv_rwlock_wrlock(&client_map_rwlock);
		client_map[client->socket] = new_sock;
		uv_rwlock_wrunlock(&client_map_rwlock);

        uv_read_start((uv_stream_t*)client, alloc_buffer, after_read);
    }
    else {
        uv_close((uv_handle_t*) client, NULL);
    }
}

//L_onTick L_onRPC L_onMysql
void call_luafunction(char *funcname, int argn, void *data)
{
	uv_mutex_lock(&lua_mutex);
	lua_getfield(L, LUA_GLOBALSINDEX, "debug");
	lua_getfield(L,-1,"traceback");
	//printf("topIndex %d\n",lua_gettop(L));
	lua_getglobal(L,funcname);
	if(lua_isfunction(L,-1) == 0) {
		lua_pop(L,-1);
		//printf("%s is not function topIndex %d\n",funcname, lua_gettop(L));
	} else {
		if( lua_pcall(L,argn,0,2) != 0 ){
			//printf("%s Error\n",funcname);
		}
		lua_pop(L,2);
	}
	uv_mutex_unlock(&lua_mutex);
}


void tickHandler(uv_timer_t *req, int status) {
	//printf("tickHandler\n");
    call_luafunction("L_onTick",0, NULL);
}

void rpcHandler(uv_work_t *req) {
	if (rpc_queue.size() == 0) {
		return;
	}
	char *rpc_cmd = rpc_queue[0];
	uv_mutex_lock(&rpc_queue_mutex);
	db_queue.pop_front();
	uv_mutex_unlock(&rpc_queue_mutex);
	call_luafunction("L_onRPC",1, rpc_cmd);
	free(rpc_cmd);
}



void dbHandler(uv_work_t *req) {
	//printf("dbHandler\n");
	if (db_queue.size() == 0) {
		return;
	}
	char *sql = db_queue[0];
	sql = "show databases";

	uv_mutex_lock(&db_queue_mutex);
	db_queue.pop_front();
	uv_mutex_unlock(&db_queue_mutex);

	char *data = "datadata";

	call_luafunction("L_onMysql",1, data);
}



int main() {

	L = luaL_newstate();
	luaL_openlibs(L);

	uv_mutex_init(&lua_mutex);
	uv_mutex_init(&rpc_queue_mutex);
	uv_mutex_init(&db_queue_mutex);
	uv_rwlock_init(&client_map_rwlock);

	uv_mutex_lock(&lua_mutex);
	char *file = "./init.lua";
	if(luaL_dofile(L,file) == 1)
	{
		printf(lua_tostring(L,-1),"%s\n");
		return 1;
	}
	uv_mutex_unlock(&lua_mutex);




    loop = uv_default_loop();

    uv_tcp_t server;
    uv_tcp_init(loop, &server);

    struct sockaddr_in bind_addr = uv_ip4_addr("0.0.0.0", 7000);
    uv_tcp_bind(&server, bind_addr);
    int r = uv_listen((uv_stream_t*) &server, 128, on_new_connection);
    if (r) {
        fprintf(stderr, "Listen error %s\n", uv_err_name(uv_last_error(loop)));
        return 1;
    }

	uv_timer_t timer_req;
	uv_timer_init(loop, &timer_req);
	uv_timer_start(&timer_req, tickHandler, 3000, 100);

	// rpc 线程
	uv_work_t req_rpc;
	uv_queue_work(loop, &req_rpc, rpcHandler, NULL);

	// db 线程
	uv_work_t req_db;
	req_db.data = "req_db";
	uv_queue_work(loop, &req_db, dbHandler, NULL);
    return uv_run(loop, UV_RUN_DEFAULT);
}

