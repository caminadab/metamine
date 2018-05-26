ontleed.so: main.c taal.tab.c
	gcc -shared -o ontleed.so -fPIC main.c taal.tab.c

taal.tab.c: taal.y
	bison taal.y

ontleed: main.c taal.tab.c
	gcc -ggdb -o ontleed main.c taal.tab.c -lm -llua 
