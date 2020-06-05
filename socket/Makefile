socket.so: main.c
	mkdir -p bin
	gcc -g -Wall -Wno-unused -std=c11 -shared -I/usr/include/lua5.1 -o bin/socket.so -fPIC main.c -Wno-multichar
	ln -sf bin/socket.so .

test: socket.so
	luajit test.lua
