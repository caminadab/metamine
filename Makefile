linux: web/www/index.html web/www/index.en.html ontleed.so
deploy: ontleed.so web/www/
	scp -r web/www/* metamine.nl:/var/www/html/

#ssh -f pi  'cd taal ; git pull ; make ; pkill luajit ; /etc/dienst'

run: linux
	luajit web/dienst.lua

test: linux
	luajit test.lua

webdemos: web/www/ex/
	./tolk ex/pong.code web/www/ex/pong.en.code
	./tolk ex/cirkels.code web/www/ex/cirkels.en.code
	./tolk ex/salvobal.code web/www/ex/salvobal.en.code
	./tolk ex/buis.code web/www/ex/buis.en.code
	./tolk ex/paint.code web/www/ex/paint.en.code
	

ontleed.so: ontleed/lex.l ontleed/taal.y ontleed/lua.c
	cd ontleed; make linux
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	ln -sf ../bin/ontleed.so web/
	ln -sf bin/ontleed.so .
	ln -sf ../vt bin/
	ln -sf ../doe bin/
	
windows:
	mkdir -p bin
	cd ontleed; make windows
	cp -r ontleed/bin/* bin/
	ln -sf ../vt bin/
	ln -sf ../doe bin/


#scp -r web/* pi:/var/www/blog/taal-0.1.1

all:
	mkdir -p bin	
	cd ontleed; make
	cp -r ontleed/bin/* bin/

web/www/index.en.html: web/www/index.fmt web/www/index.en
	./sjab web/www/index.fmt web/www/index.en web/www/index.en.html

web/www/ex/demo.en.code: ex/demo.code bieb/en.lst bieb/demo.lst
	./tolk ex/demo.code web/www/ex/demo.en.code

web/www/index.nl.html: web/www/index.fmt web/www/index.nl 
	./sjab web/www/index.fmt web/www/index.nl web/www/index.nl.html

web/www/index.html: web/www/index.nl.html
	ln -sf index.nl.html web/www/index.html

web/www/en: web/www/index.en.html
	ln -sf index.en.html web/www/en

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
	rm -rf bin/
	rm -rf web/www/index.html web/www/en web/www/nl web/www/index.*.html

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
