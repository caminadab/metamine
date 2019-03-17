#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>

#include "node.h"
#include "taal.yy.h"
#include "global.h"

void yyerror (char const * s) {
	//fprintf(stderr, "%s\n", s);
}

node* ontleed(char* code) {
	node* wortel = yyparse(code);
	return wortel;
}

void test();

int main() {
	test();
	puts("klaar");
	return 0;
}
