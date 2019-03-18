#include "taal.yy.h"
#include "lex.yy.h"
#include "node.h"

int yyerror(YYLTYPE* loc, void** root, void* scanner, const char* yymsg) {
	printf("%d:%d-%d:%d: %s\n", loc->first_line, loc->first_column, loc->first_line, loc->first_column, yymsg);
}

int main() {
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string("a = ;- ok\n -; 10\n", scanner);

	// !
	YYSTYPE param;
	YYLTYPE loc;

	node* uit;
	int a = yyparse(&uit, scanner);

	printf("parse = %d\n", a);

	char buf[1024];
	write_node(uit, buf, 1024);
	puts(buf);

	yylex_destroy(scanner);

	return 0;
}
