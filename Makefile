parse: main.c sas.tab.c
	gcc -g -lm -o parse main.c sas.tab.c

sas.tab.c: sas.y
	bison sas.y
