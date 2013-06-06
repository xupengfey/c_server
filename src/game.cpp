
#include "game.h"

MYSQL* pmysql;
static lua_State* L;
static uv_mutex_t lua_mutex;

static std::deque<std::pair<int, char*> > rpc_queue;
static uv_mutex_t rpc_queue_mutex;
uv_sem_t rpc_queue_sem;

std::deque<char*> db_queue;
uv_mutex_t db_queue_mutex;
uv_sem_t db_queue_sem;


static std::map<uv_tcp_t*, Sock*> client_map;
static std::map<int, Sock*> c_sockid_map;
static uv_rwlock_t client_map_rwlock;
static int c_sock_id;
static uv_mutex_t c_sock_id_mutex;

static std::map<uv_tcp_t*, Sock*> nc_map;
static std::map<int, Sock*> nc_sockid_map;
static uv_rwlock_t nc_map_rwlock;
static int nc_sock_id;
static uv_mutex_t nc_sock_id_mutex;


uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size) {
	return uv_buf_init((char *)malloc(suggested_size), suggested_size);
}



void on_close(uv_handle_t* peer) {
  free((uv_tcp_t*)peer);
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
	//printf("after_read sock=%d\n", tcp);
	uv_shutdown_t* req = NULL;
	Sock *sock = NULL;
	int len = 0;
	int i = 0;

	if (nread < 0) {
		if (buf.base) {
			free(buf.base);
		}
		goto DEL;
	}

	if (nread == 0) {
		/* Everything OK, but nothing read. */
		free(buf.base);
		return;
	}

	if (type == 1) {
		uv_rwlock_rdlock(&client_map_rwlock);
		if (client_map.find(tcp) != client_map.end()) {
			sock = client_map[tcp];
		}
		uv_rwlock_rdunlock(&client_map_rwlock);
	} else {
		uv_rwlock_rdlock(&nc_map_rwlock);
		if (nc_map.find(tcp) != nc_map.end()) {
			sock = nc_map[tcp];
		}
		uv_rwlock_rdunlock(&nc_map_rwlock);
	}
	if (sock == NULL) {
		free(buf.base);
		return;
	}

	
	while(i < nread) {
		switch(sock->read_status) {
		case 0:
			if (sock->readed == 0) {
				sock->lenth = 0;
			}
			for (;i<nread;i++){
				if (sock->readed < 4) {
					sock->readed++;
					//printf("%d: %d: %c\n",i,(unsigned char)buf.base[i],buf.base[i]);
					sock->lenth = (sock->lenth << 8) + (unsigned char)(buf.base[i]);
				} else  {
					printf("##head end len=%d\n",sock->lenth);
					if (type == 1 && sock->lenth > 1000000 ) {
						printf("data too large error sock=%d\n", sock->sock_id);
						free(buf.base);
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

			//if (sock->lenth < 1000) {
			//	printf("full package %s\n",sock->buff);
			//}

			sock->read_status = 0;
			sock->readed = 0;
			char *cmd = (char*)malloc(sock->lenth);
			memcpy(cmd, sock->buff+1, sock->lenth);
			free(sock->buff);
			uv_mutex_lock(&rpc_queue_mutex);
			rpc_queue.push_back(std::make_pair(type,cmd));
			uv_mutex_unlock(&rpc_queue_mutex);
			uv_sem_post(&rpc_queue_sem);
		}
	}
	free(buf.base);
	return;

DEL:
	if (sock) {
		if (type == 1) {
			uv_rwlock_wrunlock(&client_map_rwlock);
			client_map.erase(sock->handle);
			c_sockid_map.erase(sock->sock_id);
			uv_rwlock_wrunlock(&client_map_rwlock);
		} else {
			uv_rwlock_wrunlock(&nc_map_rwlock);
			nc_map.erase(sock->handle);
			nc_sockid_map.erase(sock->sock_id);
			uv_rwlock_wrunlock(&nc_map_rwlock);
		}
		if (sock->buff) {
			free(sock->buff);
		}
		free(sock);
	}
	uv_close((uv_handle_t*)handle, on_close);	
}

void after_send(uv_write_t* req, int status){
	uv_buf_t* pbuf = (uv_buf_t*)req->data;
	free(pbuf->base);
	free(pbuf);
	free(req);
}

void senddata(int sock_id, int type, const char* str){
	//printf("senddata sock_id=%d type=%d str=%s\n",sock_id,type,str);
	Sock* sock = NULL;
	if (type == 1) {
		uv_rwlock_rdlock(&client_map_rwlock);
		if (c_sockid_map.find(sock_id) != c_sockid_map.end()) {
			sock = c_sockid_map[sock_id];
		}
		uv_rwlock_rdunlock(&client_map_rwlock);
	} else {
		uv_rwlock_rdlock(&nc_map_rwlock);
		if (nc_sockid_map.find(sock_id) != nc_sockid_map.end()) {
			sock = nc_sockid_map[sock_id];
		}
		uv_rwlock_rdunlock(&nc_map_rwlock);
	}

	
	if (sock) {
		uv_write_t* req = (uv_write_t*) malloc(sizeof(uv_write_t));
		uv_buf_t *pbuf = (uv_buf_t*)malloc(sizeof(uv_buf_t));
		
		int i;
		int str_len = strlen(str);
		int data_len = str_len + 1;
		int buf_len = data_len + 4;
		pbuf->base = (char*)malloc(buf_len);
		for(i=3; i>=0; i--) {
			pbuf->base[i] = data_len % (1<<8);
			data_len = data_len >> 8;
		}
		pbuf->base[4] = 0; //占位 压缩 协议 等标识
		memcpy(pbuf->base+5,str,str_len);
		pbuf->len = buf_len;
		//free((char*)str);
		req->data = pbuf;
		if (uv_write(req, (uv_stream_t*)sock->handle, pbuf, 1, after_send)) {
			printf("[Error] uv_write failed\n");	
			free(pbuf->base);
			free(pbuf);
			free(req);
		}
	} else {
		printf("sock not exist sock_id=%d type=%d\n",sock_id,type);
	}

}





void tickHandler(uv_timer_t *req, int status) {
	
	uv_mutex_lock(&lua_mutex);
	//printf("tickHandler stack top %d\n",lua_gettop(L));
	lua_getglobal(L,lua_cmd_type_name[L_onError]);
	lua_getglobal(L,lua_cmd_type_name[L_onTick]);
	if (lua_pcall(L,0,0,-2) == 0) {
		lua_pop(L,1);
	} else {
		lua_pop(L,2);
	}
	//printf("after tickHandler stack top %d\n",lua_gettop(L));
	uv_mutex_unlock(&lua_mutex);
}

void rpcHandler(uv_work_t *req) {
	while (true) {
		//if (rpc_queue.size() == 0) {
		//	uv_sleep(1);
		//	continue;
		//}
		uv_sem_wait(&rpc_queue_sem);
		
		uv_mutex_lock(&rpc_queue_mutex);
		std::pair<int, char*> cmd = rpc_queue[0];
		rpc_queue.pop_front();
		uv_mutex_unlock(&rpc_queue_mutex);
		char *json_cmd = cmd.second;
		
		uv_mutex_lock(&lua_mutex);
		//printf("call_luarpc stack top %d\n",lua_gettop(L));
		lua_getglobal(L,lua_cmd_type_name[L_onError]);
		lua_getglobal(L,lua_cmd_type_name[L_onRPC]);
		lua_pushinteger(L,cmd.first);
		lua_pushstring(L,json_cmd);
		if (lua_pcall(L,2,0,-4) == 0) {
			lua_pop(L,1);
		} else {
			lua_pop(L,2);
		}
		//printf("after call_luarpc stack top %d\n",lua_gettop(L));
		uv_mutex_unlock(&lua_mutex);
		free(json_cmd);
	
	}


}





void dbHandler(uv_work_t *req) {
	//printf("dbHandler\n");
	while(true) {
		uv_sem_wait(&db_queue_sem);
		//if (db_queue.size() == 0) {
		//	continue;
		//}
	
		uv_mutex_lock(&db_queue_mutex);
		char *sql = db_queue[0];
		db_queue.pop_front();
		uv_mutex_unlock(&db_queue_mutex);

		if (mysql_query(pmysql, sql)){
			printf("%s\n", mysql_error(pmysql));
			printf("sql:%s\n",sql);
			uv_mutex_lock(&lua_mutex);
			lua_getglobal(L,lua_cmd_type_name[L_onError]);
			lua_getglobal(L,lua_cmd_type_name[L_onMysql]);
			lua_pushinteger(L, mysql_errno(pmysql));
			if (lua_pcall(L,1,0,1) == 0) {
				lua_pop(L,1);
			} else {
				lua_pop(L,2);
			}
			uv_mutex_unlock(&lua_mutex);
			free(sql);
			continue;
		}
		free(sql);
		MYSQL_RES *res;
		MYSQL_ROW row;
		MYSQL_FIELD *fields;
		int num_fields;
		int i;

		res = mysql_store_result(pmysql);

		if (res == NULL) {
			uv_mutex_lock(&lua_mutex);
			lua_getglobal(L,lua_cmd_type_name[L_onError]);
			lua_getglobal(L,lua_cmd_type_name[L_onMysql]);
			lua_pushinteger(L, mysql_errno(pmysql));
			if (lua_pcall(L,1,0,1) == 0) {
				lua_pop(L,1);
			} else {
				lua_pop(L,2);
			}
			uv_mutex_unlock(&lua_mutex);
			continue;
		}

		num_fields = mysql_num_fields(res);
		fields = mysql_fetch_fields(res);

		uv_mutex_lock(&lua_mutex);
		lua_getglobal(L,lua_cmd_type_name[L_onError]);
		lua_getglobal(L,lua_cmd_type_name[L_onMysql]);
		int rowi = 1;
		lua_newtable(L);
		int top = lua_gettop(L);
	/*	printf("top=%d\n",top);*/
		while((row = mysql_fetch_row(res))) {
			lua_pushnumber( L, rowi );
			rowi++;
			lua_newtable(L);
			int topRow = lua_gettop(L);
			//printf("topRow=%d\n",topRow);
			for (i=0; i <num_fields; i++) {
				lua_pushstring(L,fields[i].name);
				if (MYSQL_TYPE_NULL == fields[i].type){
					lua_pushnil(L);
				} else if (IS_NUM(fields[i].type)) {
					lua_pushnumber(L, strtod(row[i],NULL));
				} else if (fields[i].type>=MYSQL_TYPE_TINY_BLOB && fields[i].type <= MYSQL_TYPE_BLOB) {
					if (row[i] == NULL || strlen((char*)row[i]) == 0) {
						lua_pushnil(L);
					} else {
						lua_getglobal(L,lua_cmd_type_name[L_decode]);
						lua_pushstring(L,row[i]);
						lua_pcall(L,1,1,1);
					}
				} else {
					lua_pushstring(L,row[i]);
				}
				lua_settable(L,-3);
			}
			lua_settable(L,top);
		}
		
		//printf("dbHandler top stack %d\n",lua_gettop(L));
		if (lua_pcall(L,1,0,1) == 0) {
			lua_pop(L,1);
		} else {
			lua_pop(L,2);
		}
		uv_mutex_unlock(&lua_mutex);
		mysql_free_result(res);
	}

}

int listen_port(int port)
{
	uv_tcp_t* ptcp_server = (uv_tcp_t*)malloc(sizeof(uv_tcp_t));
	uv_tcp_init(uv_default_loop(), ptcp_server);
	struct sockaddr_in bind_addr = uv_ip4_addr("0.0.0.0", port);
    uv_tcp_bind(ptcp_server, bind_addr);
    int r = uv_listen((uv_stream_t*) ptcp_server, 128, on_new_connection);
    if (r) {
        fprintf(stderr, "Listen error %s\n", uv_err_name(uv_last_error(uv_default_loop())));
		free(ptcp_server);
        return 1;
    }
	return 0;
}

int gen_c_sockid()
{
	uv_mutex_lock(&c_sock_id_mutex);
	c_sock_id++;
	uv_mutex_unlock(&c_sock_id_mutex);
	return c_sock_id;	
}

int gen_nc_sockid()
{
	uv_mutex_lock(&nc_sock_id_mutex);
	nc_sock_id++;
	uv_mutex_unlock(&nc_sock_id_mutex);
	return nc_sock_id;
}

void on_new_connection(uv_stream_t *server, int status) {
    if (status == -1) {
        // error!
        return;
    }

    uv_tcp_t *client = (uv_tcp_t*) malloc(sizeof(uv_tcp_t));
    uv_tcp_init(uv_default_loop(), client);
    if (uv_accept(server, (uv_stream_t*) client) == 0) {
		Sock* new_sock = (Sock*)malloc(sizeof(Sock));
		memset(new_sock,0,sizeof(*new_sock));
		new_sock->sock_id = gen_nc_sockid();
		new_sock->handle = client;
		new_sock->read_status = 0;
		new_sock->readed = 0;
		uv_rwlock_wrlock(&client_map_rwlock);
		c_sockid_map[new_sock->sock_id] = new_sock;
		client_map[client] = new_sock;
		uv_rwlock_wrunlock(&client_map_rwlock);


        uv_read_start((uv_stream_t*)client, alloc_buffer, read_client_cb);

    }
    else {
        uv_close((uv_handle_t*) client, NULL);
    }
}


void connect_cb(uv_connect_t* req, int status) {
	if (status == -1) {
		printf("connect failed\n");
		free(req);
		return;
	}
	Sock* new_sock = (Sock*)malloc(sizeof(Sock));
	memset(new_sock,0,sizeof(*new_sock));
	new_sock->sock_id = gen_nc_sockid();
	new_sock->handle = (uv_tcp_t*)req->handle;
	new_sock->read_status = 0;
	new_sock->readed = 0;
	uv_rwlock_wrlock(&nc_map_rwlock);
	nc_map[(uv_tcp_t*)req->handle] = new_sock;
	nc_sockid_map[new_sock->sock_id] = new_sock;
	uv_rwlock_wrunlock(&nc_map_rwlock);

	uv_mutex_lock(&lua_mutex);
		//printf("call_luarpc stack top %d\n",lua_gettop(L));
	lua_getglobal(L,lua_cmd_type_name[L_onError]);
	lua_getglobal(L,lua_cmd_type_name[L_onConnectedNC]);
	lua_pushinteger(L,new_sock->sock_id);

	if (lua_pcall(L,1,0,-3) == 0) {
		lua_pop(L,1);
	} else {
		lua_pop(L,2);
	}
		//printf("after call_luarpc stack top %d\n",lua_gettop(L));
	uv_mutex_unlock(&lua_mutex);

	uv_read_start(req->handle, alloc_buffer, read_nc_cb); 
	free(req);

}
//uv_connect_t connect_req;
//uv_tcp_t tcp_client;
int tcp_connect(const char* ip, int port)
{
	uv_connect_t* pconnect_req = (uv_connect_t *)malloc(sizeof(uv_connect_t));
	uv_tcp_t* ptcp_client = (uv_tcp_t *)malloc(sizeof(uv_tcp_t));
	uv_tcp_init(uv_default_loop(), ptcp_client);
	struct sockaddr_in server_addr = uv_ip4_addr(ip, port);
	return uv_tcp_connect(pconnect_req, ptcp_client,server_addr,connect_cb);
}


int main(int argc, char** argv) {

	uv_mutex_init(&lua_mutex);
	uv_mutex_init(&rpc_queue_mutex);
	uv_sem_init(&rpc_queue_sem, 0);

	uv_mutex_init(&db_queue_mutex);
	uv_sem_init(&db_queue_sem, 0);
	uv_mutex_init(&c_sock_id_mutex);
	uv_mutex_init(&nc_sock_id_mutex);
	
	uv_rwlock_init(&client_map_rwlock);
	uv_rwlock_init(&nc_map_rwlock);




	// 启动lua虚拟机
	uv_mutex_lock(&lua_mutex);
	L = luaL_newstate();
	luaL_openlibs(L);
	luaopen_cjson(L);
	registerAPI(L);
	char *file = "./init.lua";
	if(luaL_dofile(L,file) == 1)
	{
		printf(lua_tostring(L,-1),"%s\n");
		//return 1;
	}
	lua_pop(L,lua_gettop(L));
	uv_mutex_unlock(&lua_mutex);


	// dotick 定时器
	uv_timer_t timer_req;
	uv_timer_init(uv_default_loop(), &timer_req);
	uv_timer_start(&timer_req, tickHandler, 3000, 100);

	// rpc 线程
	uv_work_t req_rpc;
	uv_queue_work(uv_default_loop(), &req_rpc, rpcHandler, NULL);

	// db 线程
	uv_work_t req_db;
	uv_queue_work(uv_default_loop(), &req_db, dbHandler, NULL);

    return uv_run(uv_default_loop(), UV_RUN_DEFAULT);
}

