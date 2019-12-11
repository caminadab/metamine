linux: goo/www/index.html goo/www/index.en.html ontleed.so
deploy: ontleed.so goo/www/
	scp -r goo/www/* metamine.nl:/var/www/html/
	ssh -f pi  'cd taal ; git pull ; make ; pkill luajit ; /etc/dienst'

run: linux
	luajit goo/dienst.lua

test: linux
	luajit test.lua
	

ontleed.so: ontleed/lex.l ontleed/taal.y ontleed/lua.c
	cd ontleed; make linux
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	ln -sf ../bin/ontleed.so goo/
	ln -sf bin/ontleed.so .
	ln -sf ../vt bin/
	ln -sf ../doe bin/
	
windows:
	mkdir -p bin
	cd ontleed; make windows
	cp -r ontleed/bin/* bin/
	ln -sf ../vt bin/
	ln -sf ../doe bin/


#scp -r goo/* pi:/var/www/blog/taal-0.1.1

all:
	mkdir -p bin	
	cd ontleed; make
	cp -r ontleed/bin/* bin/

goo/www/index.en.html: goo/www/index.fmt goo/www/index.en
	./sjab goo/www/index.fmt goo/www/index.en goo/www/index.en.html

goo/www/index.nl.html: goo/www/index.fmt goo/www/index.nl 
	./sjab goo/www/index.fmt goo/www/index.nl goo/www/index.nl.html

goo/www/index.html: goo/www/index.nl.html
	ln -sf index.nl.html goo/www/index.html

goo/www/en: goo/www/index.en.html
	ln -sf index.en.html goo/www/en

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
	rm -rf goo/www/index.html goo/www/en goo/www/nl goo/www/index.*.html

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
