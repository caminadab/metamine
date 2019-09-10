linux: .taal.yy.c node.c lua.c .lex.yy.c ontleed.c
	mkdir -p bin
	gcc -Wall -Wno-unused -std=c11 -shared -I/usr/include/lua5.1 -o bin/ontleed.so -fPIC ontleed.c node.c lua.c .taal.yy.c .lex.yy.c -Wno-multichar

test: ontleed.c node.c test.c .taal.yy.h .taal.yy.c .lex.yy.h .lex.yy.c
	mkdir -p bin
	gcc -g -o bin/test -std=c11 -fPIC ontleed.c .taal.yy.c node.c .lex.yy.c test.c -lm
	bin/test

windows: main.c taal.yy.c node.c lua.c
	mkdir -p bin
	gcc -std=c99 -ggdb -fPIC -shared -I/usr/include/lua5.1 -o bin/ontleed.dll main.c .taal.yy.c node.c lua.c -llua test.c .lex.yy.c

wintest: main.c .taal.yy.c node.c
	gcc -std=c99 -ggdb -o bin/test main.c .taal.yy.c lex.yy.c node.c test.c -lm

.lex.yy.h .lex.yy.c: lex.l
	flex --header-file=.lex.yy.h --outfile=.lex.yy.c lex.l

.taal.yy.h .taal.yy.c: taal.y
	bison --report=all -d -t --locations --defines=.taal.yy.h --output=.taal.yy.c taal.y

bin/ontleed: ontleed.c .taal.yy.c node.c
	gcc -ggdb -o bin/ontleed ontleed.c node.c .taal.yy.c .lex.yy.c -lm -llua

clean:
	rm -f .taal.yy.h .lex.yy.h .taal.yy.c .lex.yy.c ontleed.so ontleed

demo: main2.c .taal.yy.h .lex.yy.h node.c
	gcc -ggdb -o demo main2.c node.c taal.yy.c lex.yy.c
	./demo
