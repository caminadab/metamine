all:
	mkdir -p bin
	cd ontleed; make windows
	cp -r ontleed/bin/* bin/

all:
	mkdir -p bin	
	cd ontleed; make
	cp -r ontleed/bin/* bin/

web:
	cd ontleed; make web
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	lua2js lex.lua > bin/lex.js
	lua2js lisp.lua > bin/lisp.js
