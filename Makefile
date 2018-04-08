satis: calc.tab.c
	gcc -lm -o satis *.c

calc.tab.c: calc.y
	bison calc.y

calc.y: calc.y.0 calc.bnf
	cat calc.y.0 calc.bnf > calc.y
