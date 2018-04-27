parse: main.c sas.tab.c
	gcc -std=c99 -g -lm -o parse main.c sas.tab.c

sas.tab.c: sas.y
	bison sas.y
