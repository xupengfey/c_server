all:
	g++ -o c_server_linux src/*.cpp  -I./include/ -L./lib/linux -llua -luv -lmysqlclient -lglog -lunwind -ltcmalloc -ldl -lpthread  -lrt -lz

clean:
	rm c_server_linux
