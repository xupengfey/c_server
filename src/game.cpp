//#pragma comment (lib, "libuv.lib")
//#pragma comment (lib, "ws2_32.lib")
//#pragma comment(lib, "psapi.lib")
//#pragma comment(lib, "Iphlpapi.lib")
#include "game.h"



uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size) {
	return uv_buf_init((char *)malloc(suggested_size), suggested_size);
}

void connect_cb(uv_connect_t* req, int status) {
  if (uv_read_start(req->handle, alloc_buffer, read_nc_cb)) {
    
  }
}


void on_close(uv_handle_t* peer) {
  free(peer);
}

void read_client_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {
	do_read(1,handle,nread,buf);
}

void read_nc_cb(uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {
	do_read(2,handle,nread,buf);
}


void do_read(int type,uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {
	printf("after read %d\n", nread);
	uv_tcp_t* tcp = (uv_tcp_t*)handle;
	printf("after_read sock=%d\n", tcp->socket);
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

	if (type == 1) {
		uv_rwlock_rdlock(&client_map_rwlock);
		if (client_map.find(tcp->socket) != client_map.end()) {
			sock = client_map[tcp->socket];
		}
		uv_rwlock_rdunlock(&client_map_rwlock);
	} else {
		uv_rwlock_rdlock(&nc_map_rwlock);
		if (nc_map.find(tcp->socket) != nc_map.end()) {
			sock = nc_map[tcp->socket];
		}
		uv_rwlock_rdunlock(&nc_map_rwlock);
	}
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
					if (type == 1 && sock->lenth > 1000000 ) {
						printf("data too large error sock=%d\n", sock->sock_id);
						goto DEL;
					}

					sock->readed = 0;
					sock->buff = (char*)malloc(sock->lenth+1); // '\0
					sock->read_status = 1;
					break;
				} 
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
			//int first = (*(sock->buff))[0];
			//if (first & (1<<7) == (1<<7)) {
			//	sock->encripted = true;	
			//} else {
			//	sock->encripted = false;
			//}
			//if (first & (1<<6) == (1<<6)) {
			//	sock->compressed = true;	
			//} else {
			//	sock->compressed = false;
			//}
			//sock->protocol = first % (1<<6);

			if (sock->lenth < 1000) {
				printf("fubll package %s\n",sock->buff);
			}

			sock->read_status = 0;
			sock->readed = 0;
			//char *cmd = malloc(sock->lenth);
			//memcpy(cmd, sock->buff+1,sock->lenth);
			//if (sock->buff) {
			//	free(sock->buff);
			//}
			char *cmd = (char*)malloc(sock->lenth);
			memcpy(cmd, sock->buff+1, sock->lenth);
			free(sock->buff);
			uv_mutex_lock(&rpc_queue_mutex);
			rpc_queue.push_back(std::make_pair(type,cmd));
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

void senddata(int sock_id, int type, const char* str){
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

        uv_read_start((uv_stream_t*)client, alloc_buffer, read_client_cb);
    }
    else {
        uv_close((uv_handle_t*) client, NULL);
    }
}

//L_onTick L_onRPC L_onMysql
void call_luafunction(char *funcname, int argn, void *data)
{
	if (!L) {
		return;
	}
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
    //call_luafunction("L_onTick",0, NULL);
	uv_mutex_lock(&lua_mutex);
	lua_getfield(L, LUA_GLOBALSINDEX, "debug");
	lua_getfield(L,-1,"traceback");
	lua_getglobal(L,lua_cmd_type_name[L_onTick]);
	lua_pcall(L,0,0,2);
	lua_pop(L,2);
	uv_mutex_unlock(&lua_mutex);
}

void rpcHandler(uv_work_t *req) {
	while (true) {
		if (rpc_queue.size() == 0) {
			continue;
		}
		std::pair<int, char*> cmd = rpc_queue[0];
		uv_mutex_lock(&rpc_queue_mutex);
		rpc_queue.pop_front();
		uv_mutex_unlock(&rpc_queue_mutex);
		char *json_cmd = cmd.second;
		
		uv_mutex_lock(&lua_mutex);
		printf("call_luarpc stack top %d\n",lua_gettop(L));
		lua_getfield(L, LUA_GLOBALSINDEX, "debug");
		lua_getfield(L,-1,"traceback");
		lua_getglobal(L,lua_cmd_type_name[L_onRPC]);
		lua_pushinteger(L,cmd.first);
		lua_pushstring(L,json_cmd);
		lua_pcall(L,2,0,2);
		lua_pop(L,2);
		uv_mutex_unlock(&lua_mutex);
		free(json_cmd);
	
	}


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

int listen_port(int port)
{
	uv_tcp_init(loop, &tcp_server);
	struct sockaddr_in bind_addr = uv_ip4_addr("0.0.0.0", port);
    uv_tcp_bind(&tcp_server, bind_addr);
    int r = uv_listen((uv_stream_t*) &tcp_server, 128, on_new_connection);
    if (r) {
        fprintf(stderr, "Listen error %s\n", uv_err_name(uv_last_error(loop)));
        return 1;
    }
	return 0;
}



int main(int argc, char** argv) {

	uv_mutex_init(&lua_mutex);
	uv_mutex_init(&rpc_queue_mutex);
	uv_mutex_init(&db_queue_mutex);
	uv_rwlock_init(&client_map_rwlock);
	uv_rwlock_init(&nc_map_rwlock);

    loop = uv_default_loop();



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


	// 启动lua虚拟机
	L = luaL_newstate();
	luaL_openlibs(L);
	luaopen_cjson(L);

	registerAPI(L);
	uv_mutex_lock(&lua_mutex);
	char *file = "./init.lua";
	if(luaL_dofile(L,file) == 1)
	{
		printf(lua_tostring(L,-1),"%s\n");
		return 1;
	}
	uv_mutex_unlock(&lua_mutex);

    return uv_run(loop, UV_RUN_DEFAULT);
}

