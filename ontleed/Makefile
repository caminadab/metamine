linux: main.c taal.yy.c node.c lua.c test.c lex.yy.c
	mkdir -p bin
	gcc -std=c11 -shared -I/usr/include/lua5.2 -o bin/ontleed.so -fPIC node.c lua.c taal.yy.c lex.yy.c test.c -Wno-multichar

test: main.c node.c test.c taal.yy.h taal.yy.c lex.yy.h lex.yy.c
	mkdir -p bin
	gcc -g -o bin/test -std=c11 -fPIC main.c taal.yy.c node.c lex.yy.c test.c -lm
	bin/test

windows: main.c taal.yy.c node.c lua.c
	mkdir -p bin
	gcc -std=c99 -ggdb -fPIC -shared -I/usr/include/lua5.2 -o bin/ontleed.dll main.c taal.yy.c node.c lua.c -llua test.c lex.yy.c

wintest: main.c taal.yy.c node.c
	gcc -std=c99 -ggdb -o bin/test main.c taal.yy.c lex.yy.c node.c test.c -lm

web:
	mkdir -p bin
	emcc -o bin/em-ontleed.js -s EXPORTED_FUNCTIONS='["_main", "_ontleed"]' -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' main.c taal.yy.c node.c lex.yy.c

lex.yy.h lex.yy.c: lex.l
	flex --header-file=lex.yy.h lex.l

taal.yy.h taal.yy.c: taal.y
	bison --report=all -d -t --locations --defines=taal.yy.h --output=taal.yy.c taal.y

bin/ontleed: main.c taal.yy.c node.c
	gcc -ggdb -o bin/ontleed main.c node.c taal.yy.c lex.yy.c -lm -llua

clean:
	rm -f taal.yy.h lex.yy.h taal.yy.c lex.yy.c ontleed.so ontleed

demo: main2.c taal.yy.h lex.yy.h node.c
	gcc -ggdb -o demo main2.c node.c taal.yy.c lex.yy.c
	./demo
