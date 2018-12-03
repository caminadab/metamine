linux: main.c taal.c node.c lua.c test.c lex.c
	mkdir -p bin
	gcc -std=c11 -shared -I/usr/include/lua5.2 -o bin/ontleed.so -fPIC main.c taal.c node.c lua.c lex.c test.c -Wno-multichar

test: main.c taal.c node.c test.c lex.c
	mkdir -p bin
	gcc -g -o bin/test -std=c11 -fPIC main.c taal.c node.c lex.c test.c -lm

windows: main.c taal.c node.c lua.c
	mkdir -p bin
	gcc -std=c99 -ggdb -fPIC -shared -I/usr/include/lua5.2 -o bin/ontleed.dll main.c taal.c node.c lua.c -llua test.c lex.c

wintest: main.c taal.c node.c
	gcc -std=c99 -ggdb -o bin/test main.c taal.c node.c test.c lex.c -lm

web:
	mkdir -p bin
	emcc -o bin/em-ontleed.js -s EXPORTED_FUNCTIONS='["_main", "_ontleed"]' -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' main.c taal.c node.c lex.c


taal.h taal.c: taal.y
	bison -d -t --locations --defines=taal.h --output=taal.c taal.y

bin/ontleed: main.c taal.c node.c
	gcc -ggdb -o bin/ontleed main.c taal.c node.c lex.c -lm -llua

clean:
	rm -f taal.h taal.c ontleed.so ontleed
