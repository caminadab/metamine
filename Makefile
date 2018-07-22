pc:
	cd ontleed; make
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	
web:
	cd ontleed; make web
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	lua2js lex.lua > bin/lex.js
	lua2js lisp.lua > bin/lisp.js

clean:
	rm -r bin/
