malloc.o: malloc.c
	cc -c -fPIC -DLACKS_STDLIB_H -DONLY_MSPACES -DNO_MALLOC_STATS malloc.c

demo.o: demo.s
	as demo.s -g -o demo.o --no-pad-sections -R 

demo: malloc.o demo.o
	ld malloc.o demo.o -lc -o demo

demofast: malloc.o demo.o
	ld demo.o -G -o demo -n --build-id=none -static 

debug:
	gcc -fPIC -ggdb -nostdlib demo.s malloc.c -o demo

release:
	gcc -Os -nostdlib demo.s malloc.c -o demo
	strip demo
