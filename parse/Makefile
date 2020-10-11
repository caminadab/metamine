linux: parse.so

parse.so: lua.c .lex.yy.h .lex.yy.c .lang.yy.h .lang.yy.c
	mkdir -p bin
	gcc -g -Wall -Wno-unused -std=c11 -shared -I/usr/include/lua5.1 -o bin/parse.so -fPIC lua.c .lang.yy.c .lex.yy.c -Wno-multichar
	ln -sf bin/parse.so .

test: test.c lua.c .lang.yy.h .lang.yy.c .lex.yy.h .lex.yy.c
	mkdir -p bin
	gcc -g -o bin/test -std=c11 -I/usr/include/lua5.1 -fPIC .lang.yy.c .lex.yy.c test.c lua.c -lm -llua5.1
	bin/test

windows: main.c lang.yy.c lua.c
	mkdir -p bin
	gcc -std=c99 -O2 -ggdb -fPIC -shared -I/usr/include/lua5.1 -o bin/parse.dll main.c .lang.yy.c lua.c -llua test.c .lex.yy.c

wintest: main.c .lang.yy.c
	gcc -std=c99 -ggdb -o bin/test main.c .lang.yy.c .lex.yy.c test.c -lm --lua5.1

.lex.yy.h .lex.yy.c: lex.l
	flex --header-file=.lex.yy.h --outfile=.lex.yy.c lex.l

.lang.yy.h .lang.yy.c: lang.y
	bison --report=all -d -t --locations --defines=.lang.yy.h --output=.lang.yy.c lang.y

bin/parse: .lang.yy.c
	gcc -ggdb -o bin/parse .lang.yy.c .lex.yy.c -lm -llua

clean:
	rm -f .lang.yy.h .lex.yy.h .lang.yy.c .lex.yy.c parse.so parse
