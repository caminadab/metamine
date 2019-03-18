#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>

#include "node.h"
#include "taal.yy.h"
#include "lex.yy.h"
#include "global.h"

void yyerror (char const * s) {
	//fprintf(stderr, "%s\n", s);
}

char* ontleed(char* code) {
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	node* wortel;

	int ok = yyparse(&wortel, scanner);
	yylex_destroy(scanner);

	char* buf = malloc(1024 * 1024);

	write_node(wortel, buf, 1024 * 1024);

	return buf;
}

void test();

int main() {
	test();
	puts("klaar");
	return 0;
}
