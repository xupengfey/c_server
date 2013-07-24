
#include "game.h"

static char global_protocol = (1 << 6) | (1 << 4);
uv_loop_t* tcp_loop;
MYSQL* pmysql;
static lua_State* L;
static uv_mutex_t lua_mutex;

uv_sem_t tcp_loop_sem;

static std::queue<RpcQueBuff* > rpc_queue;
static uv_mutex_t rpc_queue_mutex;
static uv_sem_t rpc_queue_sem;

static queue<ConQueBuff* > con_queue;
static uv_mutex_t con_queue_mutex;

std::queue<SendQueBuff* > send_queue;
uv_mutex_t send_queue_mutex;
uv_sem_t send_queue_sem;

std::queue<char*> db_queue;
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

uv_async_t async;


uv_buf_t alloc_buffer(uv_handle_t* handle, size_t suggested_size) {
	return uv_buf_init((char *)malloc(suggested_size), suggested_size);
}

void free_rpc_buf(RpcQueBuff *pbuf)
{
	free(pbuf->data);
	free(pbuf);
}

void free_send_req(uv_write_t *req)
{	
	if (req) {
		SendDataBuff* psend_data_buf =  (SendDataBuff*)req->data;
		if (psend_data_buf && psend_data_buf->num == 0) {
			free(psend_data_buf->puv_buf->base);
			free(psend_data_buf->puv_buf);
			free(psend_data_buf);
			free(req);
			req = NULL;
		}
	}
}

void free_send_queue(SendQueBuff *buf)
{
	if(buf) {
		if (buf->psock) {
			free(buf->psock);
			buf->psock = NULL;
		}
		if(buf->data) {
			free(buf->data);
			buf->data = NULL;
		}
		buf = NULL;
	}
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
	//printf("after read %d\n", nread);
	uv_tcp_t* tcp = (uv_tcp_t*)handle;
	//printf("after_read sock=%d\n", tcp);
	uv_shutdown_t* req = NULL;
	Sock *sock = NULL;
	int len = 0;
	int i = 0;

	if (type == 1) {
		uv_rwlock_rdlock(&client_map_rwlock);
		sock = client_map[tcp];
		uv_rwlock_rdunlock(&client_map_rwlock);
	} else {
		uv_rwlock_rdlock(&nc_map_rwlock);
		sock = nc_map[tcp];
		uv_rwlock_rdunlock(&nc_map_rwlock);
	}
	if (sock == NULL) {
		free(buf.base);
		return;
	}

	if (nread < 0) {
		if (buf.base) {
			free(buf.base);
		}
		goto DEL;
	}

	if (nread == 0) {
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
					//printf("##head end len=%d\n",sock->lenth);
					if (type == 1 && sock->lenth > (1<<28) ) {
						MYLOG(ERROR) << "data too large error sock=" << sock->sock_id << " len:" << sock->lenth << endl;
						free(buf.base);
						goto DEL;
					}

					sock->readed = 0;
					sock->buff = (char*)malloc(sock->lenth); 
					sock->read_status = 1;
					break;
				} 
			}
			if (i == nread) {
				free(buf.base);
				return;
			}
		case 1:
			len = sock->lenth-sock->readed<(nread-i)?sock->lenth-sock->readed:(nread-i);
			if (len > 0) {
				memcpy(sock->buff+sock->readed, buf.base+i, len);
				sock->readed += len;
				i += len;
			}
			if (sock->readed == sock->lenth) {
				sock->read_status = 2;
			} else {
				free(buf.base);
				return;
			}
		case 2:
			//sock->protocol = sock->buff[0];
			sock->read_status = 0;
			sock->readed = 0;
			int cmd_len = sock->lenth-1;
			char *cmd = (char*)malloc(cmd_len);
			memcpy(cmd, sock->buff+1, cmd_len);

			RpcQueBuff *pbuf = (RpcQueBuff*)malloc(sizeof(RpcQueBuff));
			pbuf->protocol = sock->buff[0];
			pbuf->dest_type = type;
			pbuf->sock_id = sock->sock_id;
			pbuf->data_len = cmd_len;
			pbuf->data = cmd;

			free(sock->buff);
			sock->buff = NULL;

			uv_mutex_lock(&rpc_queue_mutex);
			rpc_queue.push(pbuf);
			uv_mutex_unlock(&rpc_queue_mutex);
			uv_sem_post(&rpc_queue_sem);
		}
	}
	free(buf.base);
	return;

DEL:
	if (sock) {
		if (type == 1) {
			uv_rwlock_wrlock(&client_map_rwlock);
			client_map.erase(sock->handle);
			c_sockid_map.erase(sock->sock_id);
			uv_rwlock_wrunlock(&client_map_rwlock);

			uv_mutex_lock(&lua_mutex);
			lua_getglobal(L,lua_cmd_type_name[L_onError]);
			lua_getglobal(L,lua_cmd_type_name[L_onClose]);
			lua_pushinteger(L,sock->sock_id);
			if (lua_pcall(L,1,0,1) == 0) {
				lua_pop(L,1);
			} else {
				lua_pop(L,2);
			}
			uv_mutex_unlock(&lua_mutex);

		} else {
			uv_rwlock_wrlock(&nc_map_rwlock);
			nc_map.erase(sock->handle);
			nc_sockid_map.erase(sock->sock_id);
			uv_rwlock_wrunlock(&nc_map_rwlock);

			uv_mutex_lock(&lua_mutex);
			lua_getglobal(L,lua_cmd_type_name[L_onError]);
			lua_getglobal(L,lua_cmd_type_name[L_onCloseNC]);
			lua_pushinteger(L,sock->sock_id);
			if (lua_pcall(L,1,0,1) == 0) {
				lua_pop(L,1);
			} else {
				lua_pop(L,2);
			}
			uv_mutex_unlock(&lua_mutex);
			
		}
		if (sock->buff) {
			free(sock->buff);
		}
		free(sock);
	}
	uv_close((uv_handle_t*)handle, on_close);	
}

void closeSocket(int type, int sock_id)
{
	Sock *sock = NULL;
	if (type == 1) {
		uv_rwlock_wrlock(&client_map_rwlock);
		sock = c_sockid_map[sock_id];
		if (sock) {
			client_map.erase(sock->handle);
			c_sockid_map.erase(sock->sock_id);
		}
		uv_rwlock_wrunlock(&client_map_rwlock);
	} else {
		uv_rwlock_wrlock(&nc_map_rwlock);
		sock = nc_sockid_map[sock_id];
		if (sock) {
			nc_map.erase(sock->handle);
			nc_sockid_map.erase(sock->sock_id);
		}
		uv_rwlock_wrunlock(&nc_map_rwlock);
	}

	if (sock) {
		uv_close((uv_handle_t*)sock->handle, on_close);
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

		
		
		uv_sem_wait(&rpc_queue_sem);
		
		uv_mutex_lock(&rpc_queue_mutex);
		RpcQueBuff* pbuf = rpc_queue.front();
		rpc_queue.pop();
		uv_mutex_unlock(&rpc_queue_mutex);
		char *dest = NULL;
		uLong dest_len;
		int ret;
		char protocol = pbuf->protocol;
		// 根据protocol生成cmd
		if (IS_ENCRYPT(protocol)) {
			// 解密
			MYLOG(INFO) << "unencrypt" << endl;
			iunencrypt(pbuf->data,pbuf->data_len);
		}

		if (IS_COMPRESS(protocol)) {
			// 解压缩
			MYLOG(INFO) << "uncompress" << endl;
			dest_len = *(uLong*)pbuf->data;
			dest = (char *)malloc(dest_len);
			ret = uncompress((Bytef *)dest, &dest_len, (Bytef *)pbuf->data+sizeof(uLong), pbuf->data_len-sizeof(uLong));
			if (ret != Z_OK) {
				MYLOG(ERROR) << "uncompress error ret=" << ret << endl;
				free(dest);
				free_rpc_buf(pbuf);
				continue;
			}
		}

		uv_mutex_lock(&lua_mutex);
		//printf("call_luarpc stack top %d\n",lua_gettop(L));
		lua_getglobal(L,lua_cmd_type_name[L_onError]);
		lua_getglobal(L,lua_cmd_type_name[L_onRPC]);
		lua_pushinteger(L,pbuf->dest_type);
		lua_pushinteger(L,pbuf->sock_id);
		if (protocol & 1) {
			// amf协议
		} else {
			if (dest == NULL) {
				ret = json_decode(L, pbuf->data, pbuf->data_len);
			} else {
				ret = json_decode(L, dest, dest_len);
				free(dest);
			}
			if (ret != 0) {
				MYLOG(ERROR) << "json_decode error ret=" << ret << endl;
				lua_pop(L,lua_gettop(L));
				uv_mutex_unlock(&lua_mutex);
				free_rpc_buf(pbuf);
				continue;
			}
			
		}
		if (lua_pcall(L,3,0,1) == 0) {
			lua_pop(L,1);
		} else {
			lua_pop(L,2);
		}
		//printf("after call_luarpc stack top %d\n",lua_gettop(L));
		uv_mutex_unlock(&lua_mutex);
		free_rpc_buf(pbuf);
	}
}



void after_send(uv_write_t* req, int status){
	//MYLOG(INFO) << "after_send status:" << status << endl;
	if (status == 0 && req) {
		SendDataBuff* psend_data_buf =  (SendDataBuff*)req->data;
		psend_data_buf->num --;
		free_send_req(req);
	}
}



// void sendHandler(uv_work_t *req) {
void sendHandler(uv_async_t *handle, int status ) {
	 // uv_sem_wait(&tcp_loop_sem);
	 // uv_run(tcp_loop, UV_RUN_NOWAIT);
	//uv_run(tcp_loop, UV_RUN_ONCE);
	while (true) {
		tickHandler(NULL, 0);
		// uv_sem_wait(&send_queue_sem);
		uv_mutex_lock(&send_queue_mutex);
		 if (send_queue.size() == 0) {
		 	uv_mutex_unlock(&send_queue_mutex);
			uv_sleep(5);
		 	continue;
		 }
		SendQueBuff* send_buf = send_queue.front();
		send_queue.pop();
		uv_mutex_unlock(&send_queue_mutex);

		uLong dest_len = 0;
		char *dest = NULL;
		int ret = 0;
		if (IS_COMPRESS(global_protocol)) {
			//MYLOG(INFO) << "compress" << endl;
			dest_len = compressBound((uLong)send_buf->data_len);
			dest = (char *)malloc(dest_len+sizeof(uLong));
			*(uLong*)dest = send_buf->data_len;

			ret = compress((Bytef *)dest+sizeof(uLong), &dest_len, (Bytef *)send_buf->data, (uLong)send_buf->data_len);

			if (ret != Z_OK) {
				MYLOG(ERROR) << "compress error ret=" << ret << endl;
				free_send_queue(send_buf);
				free(dest);
				continue;
			}
	
		}

		if (IS_ENCRYPT(global_protocol)) {
			//MYLOG(INFO) << "encrypt" << endl;
			iencrypt(dest, dest_len+sizeof(uLong));
		}

		int i;
		int data_len = dest_len+sizeof(uLong) + 1; // +1 协议
		int buf_len = data_len + 4; // +4 包长度 +1 协议
		char *new_buf = (char*)malloc(buf_len);
		if (new_buf == NULL) {
			MYLOG(ERROR) << "malloc failed in sendHandler len:" << buf_len << endl;
			free_send_queue(send_buf);
			free(dest);
			continue;
		}
		for(i=3; i>=0; i--) {
			new_buf[i] = data_len % (1<<8);
			data_len = data_len >> 8;
		}
		new_buf[4] = global_protocol; //协议
		memcpy(new_buf+5, dest, buf_len-5);
		free(dest);

		SendDataBuff *psenddata_buff = (SendDataBuff*)calloc(sizeof(SendDataBuff), 1);
		psenddata_buff->puv_buf = (uv_buf_t*)malloc(sizeof(uv_buf_t));
		psenddata_buff->puv_buf->base = new_buf;
		psenddata_buff->puv_buf->len = buf_len;
		//psenddata_buff->num = send_buf->vec_sock.size();
		uv_write_t* write_req = (uv_write_t*) malloc(sizeof(uv_write_t));
		write_req->data = psenddata_buff;

		Sock* sock = NULL;


		if (send_buf->dest_type == 1) {
			uv_rwlock_rdlock(&client_map_rwlock);
			if (send_buf->psock ) {
				psenddata_buff->num = send_buf->psock[0];
				for (i=1; i <= psenddata_buff->num; i++ ) {
					sock = c_sockid_map[send_buf->psock[i]];
					if (sock) {
						if (uv_write(write_req, (uv_stream_t*)sock->handle, psenddata_buff->puv_buf, 1, after_send)) {	
							psenddata_buff->num --;
						}
					} else {
						psenddata_buff->num --;
					}
				}
			} else {
				psenddata_buff->num = c_sockid_map.size();
				std::map<uv_tcp_t*, Sock*>::iterator it=client_map.begin();
				for(; it != client_map.end(); it++) {
					sock = it->second;
					if (uv_write(write_req, (uv_stream_t*)sock->handle, psenddata_buff->puv_buf, 1, after_send)) {	
							psenddata_buff->num --;
						}
				}
			}
			uv_rwlock_rdunlock(&client_map_rwlock);
		} else {
			uv_rwlock_rdlock(&nc_map_rwlock);
			if (send_buf->psock) {
				psenddata_buff->num = send_buf->psock[0];
				for (i=1; i <= psenddata_buff->num; i++ ) {
					sock = nc_sockid_map[send_buf->psock[i]];
					
					if (sock) {
						if (uv_write(write_req, (uv_stream_t*)sock->handle, psenddata_buff->puv_buf, 1, after_send)) {	
							psenddata_buff->num --;
						} else {
						}
					} else {
						psenddata_buff->num --;
					}
				}
			} else {
				psenddata_buff->num = nc_sockid_map.size();
				std::map<uv_tcp_t*, Sock*>::iterator it=nc_map.begin();
				for(; it != nc_map.end(); it++) {
					sock = it->second;
					if (uv_write(write_req, (uv_stream_t*)sock->handle, psenddata_buff->puv_buf, 1, after_send)) {	
						psenddata_buff->num --;
					} else {
						
					}
				}
			}
			uv_rwlock_rdunlock(&nc_map_rwlock);
		}
		free_send_queue(send_buf);
		free_send_req(write_req);

	}

}

void cmdHandler(uv_work_t *req) {
	char buf[128];
	char cmd[8];
	char fileName[64];
	while(cin.getline(buf,128)) {
		memset(cmd, 0, 8);
		memset(fileName, 0, 64);
		sscanf(buf, "%s %s", cmd, fileName);
		uv_mutex_lock(&lua_mutex);
		lua_getglobal(L,lua_cmd_type_name[L_onError]);
		lua_getglobal(L,lua_cmd_type_name[L_onCommand]);
		lua_pushstring(L,cmd);
		lua_pushstring(L,fileName);
		if (lua_pcall(L,2,0,1) == 0) {
			lua_pop(L,1);
		} else {
			lua_pop(L,2);
		}
		uv_mutex_unlock(&lua_mutex);
	}

}





void dbHandler(uv_work_t *req) {
	//printf("dbHandler\n");
	while(true) {
		uv_sem_wait(&db_queue_sem);
		uv_mutex_lock(&db_queue_mutex);
		char *sql = db_queue.front();
		db_queue.pop();
		uv_mutex_unlock(&db_queue_mutex);

		if (mysql_query(pmysql, sql)){
			MYLOG(ERROR) << mysql_error(pmysql) << endl;
			MYLOG(ERROR) << "sql:" << sql << endl;
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
						json_decode(L, row[i], strlen(row[i]));
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
		MYLOG(ERROR) << "Listen error" << uv_err_name(uv_last_error(uv_default_loop())) << endl;
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
    // uv_sem_post(&tcp_loop_sem);
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

		uv_mutex_lock(&lua_mutex);
		lua_getglobal(L,lua_cmd_type_name[L_onError]);
		lua_getglobal(L,lua_cmd_type_name[L_onConnected]);
		lua_pushinteger(L,new_sock->sock_id);
		if (lua_pcall(L,1,0,-3) == 0) {
			lua_pop(L,1);
		} else {
			lua_pop(L,2);
		}
		uv_mutex_unlock(&lua_mutex);
        uv_read_start((uv_stream_t*)client, alloc_buffer, read_client_cb);

  //       ConQueBuff *pConQueBuff = (ConQueBuff*)malloc(sizeof(ConQueBuff));
		// pConQueBuff->handle = (uv_stream_t *)client;
		// pConQueBuff->type = 1;
		// uv_mutex_lock(&con_queue_mutex);
		// con_queue.push(pConQueBuff);
		// uv_mutex_unlock(&con_queue_mutex);

    }
    else {
        uv_close((uv_handle_t*) client, NULL);
    }
}


void connect_cb(uv_connect_t* req, int status) {
	if (status == -1) {
		MYLOG(ERROR) << "connect failed" << endl;
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
	// ConQueBuff *pConQueBuff = (ConQueBuff*)malloc(sizeof(ConQueBuff));
	// pConQueBuff->handle = req->handle;
	// pConQueBuff->type = 2;
	// uv_mutex_lock(&con_queue_mutex);
	// con_queue.push(pConQueBuff);
	// uv_mutex_unlock(&con_queue_mutex);
	// free(req);

}
//uv_connect_t connect_req;
//uv_tcp_t tcp_client;
int tcp_connect(const char* ip, int port)
{
	uv_connect_t* pconnect_req = (uv_connect_t *)malloc(sizeof(uv_connect_t));
	uv_tcp_t* ptcp_client = (uv_tcp_t *)malloc(sizeof(uv_tcp_t));
	uv_tcp_init(uv_default_loop(), ptcp_client);
	// uv_sem_post(&tcp_loop_sem);
	struct sockaddr_in server_addr = uv_ip4_addr(ip, port);
	return uv_tcp_connect(pconnect_req, ptcp_client,server_addr,connect_cb);
}

void iencrypt(char *str, int len)
{
	int i;
	for (i = 0; i < len; i++) {
		str[i] = str[i] ^ (i%7);
	}
}
void iunencrypt(char *str, int len)
{
	int i;
	for (i = 0; i < len; i++) {
		str[i] = str[i] ^ (i%7);
	}
}
char* icompress(char *source, uLong source_len)
{
	uLong dest_len = compressBound(source_len);
	char *dest = (char *)malloc(dest_len+sizeof(uLong));
	*(uLong*)dest = source_len;

	int ret = compress((Bytef *)dest+sizeof(uLong), &dest_len, (Bytef *)source, source_len);

	if (ret != Z_OK) {
		MYLOG(ERROR) << "icompress error " << ret << endl;
	}
	return dest;
}
char* iuncompress(char *source, uLong source_len)
{
	uLong dest_len = *(uLong*)source;
	char *dest = (char *)malloc(dest_len);
	int ret = uncompress((Bytef *)dest, &dest_len, (Bytef *)source, source_len);
	if (ret != Z_OK) {
		MYLOG(ERROR) << "uncompress error " << ret << endl;
	}
	return dest;
}

int json_encode(lua_State* L) {
	lua_getglobal(L,lua_cmd_type_name[L_encode]);
	lua_insert(L,-2);
	return lua_pcall(L,1,1,0);
}

int json_decode(lua_State* L, const char* str, int len) {
	lua_getglobal(L,lua_cmd_type_name[L_decode]);
	lua_pushlstring(L, str, len);
	return lua_pcall(L,1,1,0);
}


void conHandler() {
	while(true) {
		uv_mutex_lock(&con_queue_mutex);
		if (con_queue.size() == 0) {
			uv_mutex_unlock(&con_queue_mutex);
			return;
		}
		ConQueBuff *pConQueBuff = con_queue.front();
		con_queue.pop();
		uv_mutex_unlock(&con_queue_mutex);
		if (pConQueBuff->type == 1) {
			uv_read_start((uv_stream_t*)pConQueBuff->handle, alloc_buffer, read_client_cb);
		} else {
			uv_read_start((uv_stream_t*)pConQueBuff->handle, alloc_buffer, read_nc_cb);
		}
		// free(pConQueBuff.handle);
		free(pConQueBuff);
	}
}	



int main(int argc, char** argv) {
	// init the google glog library
	google::InitGoogleLogging(argv[0]);
	const char *log_dir = "logs";
	if(ACCESS(log_dir,0) != 0)  
	{  
		if(MKDIR(log_dir) == -1)  
		{   
			printf("mkdir error: %s\n", log_dir);
		}  
	} 
	google::SetLogDestination(google::GLOG_INFO,	"logs/_info_");//"logs/info_");
	google::SetLogDestination(google::GLOG_ERROR,	"logs/_error_");

	MYLOG(INFO) << "glog init ..." << endl;

	tcp_loop = uv_loop_new();
	uv_sem_init(&tcp_loop_sem, 0);


	uv_mutex_init(&lua_mutex);
	uv_mutex_init(&con_queue_mutex);

	uv_mutex_init(&rpc_queue_mutex);
	uv_sem_init(&rpc_queue_sem, 0);
	uv_mutex_init(&send_queue_mutex);
	uv_sem_init(&send_queue_sem, 0);
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
	char *file;
	if (argc > 1) {
		file = argv[1];
	} else {
		file = "./init.lua";
	}

	if(luaL_dofile(L,file) == 1)
	{
		printf(lua_tostring(L,-1),"%s\n");
		MYLOG(ERROR) << lua_tostring(L,-1) << endl;
	}
	lua_pop(L,lua_gettop(L));
	uv_mutex_unlock(&lua_mutex);

	MYLOG(INFO) << "lua virtual machine starting ..." << endl;
	// dotick 定时器
	uv_timer_t timer_req;
	uv_timer_init(uv_default_loop(), &timer_req);
	uv_timer_start(&timer_req, tickHandler, 3000, 100);

	// rpc 线程
	uv_work_t req_rpc;
	uv_queue_work(uv_default_loop(), &req_rpc, rpcHandler, NULL);


	uv_async_init(uv_default_loop(), &async, sendHandler);


	// db 线程
	uv_work_t req_db;
	uv_queue_work(uv_default_loop(), &req_db, dbHandler, NULL);

	// cmd 线程
	uv_work_t req_cmd;
	uv_queue_work(uv_default_loop(), &req_cmd, cmdHandler, NULL);


	MYLOG(INFO) << "server starting ..." << endl;
    return uv_run(uv_default_loop(), UV_RUN_DEFAULT);
}

