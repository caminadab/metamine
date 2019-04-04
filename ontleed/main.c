#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>

#include "node.h"
#include "taal.yy.h"
#include "lex.yy.h"

int yyerror(YYLTYPE* loc, void** root, void* scanner, const char* yymsg) {
	printf("TEST ERROR\n");
	print_loc(*loc);
	printf(": %s\n", yymsg);
	node* node = (struct node* )*root;
	strcpy(&node->fout, yymsg);
	return 0;
}

char* ontleed(char* code) {
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	node* wortel;

	int ok = yyparse((void**)&wortel, scanner);
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
