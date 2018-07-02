ontleed.so: main.c taal.c node.c
	gcc -shared -o ontleed.so -fPIC main.c taal.c node.c

taal.h taal.c: taal.y
	bison -d -t --defines=taal.h --output=taal.c taal.y

ontleed: main.c taal.c node.c
	gcc -ggdb -o ontleed main.c taal.c node.c -lm -llua 

clean:
	rm -f taal.h taal.c ontleed.so ontleed
