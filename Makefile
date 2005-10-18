all:
	g++ -o c_server src/*.cpp -I./include/ -L./lib/linux -llua -luv -lmysqlclient

clean:
	rm c_server
