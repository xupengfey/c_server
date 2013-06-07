all:
	g++ -o c_server src/*.cpp -I./include/ -L./lib/linux -llua -luv -lmysqlclient -lmysqlclient -ldl -lpthread  -lrt

clean:
	rm c_server
