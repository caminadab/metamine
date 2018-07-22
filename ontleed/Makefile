windows: main.c taal.c node.c lua.c
	mkdir -p bin
	gcc -std=c99 -shared -o bin/ontleed.dll main.c taal.c node.c lua.c -llua 

bin/ontleed.so: main.c taal.c node.c
	mkdir -p bin
	gcc -shared -o bin/ontleed.so -fPIC main.c taal.c node.c

web:
	mkdir -p bin
	emcc -o bin/ontleed.js -s EXPORTED_FUNCTIONS='["_main", "_ontleed"]' -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' main.c taal.c node.c

taal.h taal.c: taal.y
	bison -d -t --defines=taal.h --output=taal.c taal.y

bin/ontleed: main.c taal.c node.c
	gcc -ggdb -o ../bin/ontleed main.c taal.c node.c -lm -llua 

clean:
	rm -f taal.h taal.c ontleed.so ontleed
