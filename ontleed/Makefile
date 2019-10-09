linux: ontleed.so

ontleed.so: lua.c lex.l taal.y
	mkdir -p bin
	gcc -g -Wall -Wno-unused -std=c11 -shared -I/usr/include/lua5.1 -o bin/ontleed.so -fPIC lua.c .taal.yy.c .lex.yy.c -Wno-multichar
	ln -sf bin/ontleed.so .

test: test.c lua.c .taal.yy.h .taal.yy.c .lex.yy.h .lex.yy.c
	mkdir -p bin
	gcc -g -o bin/test -std=c11 -I/usr/include/lua5.1 -fPIC .taal.yy.c .lex.yy.c test.c lua.c -lm -llua5.1
	bin/test

windows: main.c taal.yy.c lua.c
	mkdir -p bin
	gcc -std=c99 -ggdb -fPIC -shared -I/usr/include/lua5.1 -o bin/ontleed.dll main.c .taal.yy.c lua.c -llua test.c .lex.yy.c

wintest: main.c .taal.yy.c
	gcc -std=c99 -ggdb -o bin/test main.c .taal.yy.c .lex.yy.c test.c -lm --lua5.1

.lex.yy.h .lex.yy.c: lex.l
	flex --header-file=.lex.yy.h --outfile=.lex.yy.c lex.l

.taal.yy.h .taal.yy.c: taal.y
	bison --report=all -d -t --locations --defines=.taal.yy.h --output=.taal.yy.c taal.y

bin/ontleed: .taal.yy.c
	gcc -ggdb -o bin/ontleed .taal.yy.c .lex.yy.c -lm -llua

clean:
	rm -f .taal.yy.h .lex.yy.h .taal.yy.c .lex.yy.c ontleed.so ontleed
