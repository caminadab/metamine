linux:
	cd ontleed; make linux
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	ln -sf ../bin/ontleed.so goo/ontleed.so
	ln -sf ./bin/ontleed.so ontleed.so
	ln -sf ../vt bin/vt
	ln -sf ../doe bin/doe
	
windows:
	mkdir -p bin
	cd ontleed; make windows
	cp -r ontleed/bin/* bin/
	ln -sf ../vt bin/vt
	ln -sf ../doe bin/doe

deploy:
	scp -r goo/www/* metamine.nl:/var/www/html/

#scp -r goo/* pi:/var/www/blog/taal-0.1.1

all:
	mkdir -p bin	
	cd ontleed; make
	cp -r ontleed/bin/* bin/

malloc.o: bieb/malloc.c
	cc -c -fPIC -DLACKS_STDLIB_H -DNO_MALLOC_STATS bieb/malloc.c -o bieb/malloc.o

web:
	cd ontleed; make web
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	lua2js lex.lua > bin/lex.js
	lua2js lisp.lua > bin/lisp.js

	
	lua2js lisp.lua > bin/lisp.js
	lua2js util.lua > bin/util.js
	lua2js isoleer.lua > bin/isoleer.js
	lua2js symbool.lua > bin/symbool.js
	lua2js noem.lua > bin/noem.js
	lua2js sorteer.lua > bin/sorteer.js
	lua2js vertaal.lua > bin/vertaal.js
	lua2js func.lua > bin/func.js
	lua2js graaf.lua > bin/graaf.js
	lua2js js.lua > bin/js.js
	lua2js typeer.lua > bin/typeer.js
	lua2js uitrol.lua > bin/uitrol.js

clean:
	rm -r bin/


objects := $(patsubst %.lua,%.o,$(wildcard *.lua))

main.o: main.s
	as main.s -o main.o



%.o: %.lua
	luajit -b $< $@

vt: *.lua $(objects)
	ar rcus libvt.a *.o
	gcc -nostdlib -o vt.app -Wl,--whole-archive libvt.a -Wl,--no-whole-archive -Wl,-E
#ld -o vt.app --whole-archive libvt.a --no-whole-archive -E
#,ld *.o -o vt.app

clean2:
	rm *.o
	rm *.app
	rm *.a

sources := $(wildcard *.lua)
