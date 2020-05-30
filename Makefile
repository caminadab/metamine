linux: web/www/index.html web/www/index.en.html ontleed.so
deploy: ontleed.so web/www/
	scp -r web/www/* metamine.nl:/var/www/html/

#ssh -f pi  'cd taal ; git pull ; make ; pkill lua ; /etc/dienst'

run: linux
	luajit web/dienst.lua

test: linux
	luajit test.lua

webdemos: web/www/ex/
	./tolk ex/aap5.code web/www/ex/aap5.en.code
	./tolk ex/pong.code web/www/ex/pong.en.code
	./tolk ex/cirkels.code web/www/ex/cirkels.en.code
	./tolk ex/salvobal.code web/www/ex/salvobal.en.code
	./tolk ex/buis.code web/www/ex/buis.en.code
	./tolk ex/paint.code web/www/ex/paint.en.code
	./tolk ex/paint2.code web/www/ex/paint2.en.code
	./tolk ex/grafiek.code web/www/ex/grafiek.en.code
	./tolk ex/demo.code web/www/ex/demo.en.code
	./tolk ex/leip.code web/www/ex/leip.en.code
	./tolk ex/oog.code web/www/ex/oog.en.code
	./tolk ex/schaken.code web/www/ex/schaken.en.code
	./tolk ex/voer.code web/www/ex/voer.en.code
	./tolk ex/pe1.code web/www/ex/pe1.en.code
	./tolk ex/pe2.code web/www/ex/pe2.en.code
	./tolk ex/pe3.code web/www/ex/pe3.en.code
	./tolk ex/pe4.code web/www/ex/pe4.en.code
	./tolk ex/pe5.code web/www/ex/pe5.en.code
	./tolk ex/pe6.code web/www/ex/pe6.en.code
	

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
