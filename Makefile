all:
	g++ -o c_server src/*.cpp  -I./include/ -L./lib/linux -llua -luv -lmysqlclient -lglog -lunwind -ltcmalloc -ldl -lpthread  -lrt

clean:
	rm c_server
