#include "taal.yy.h"
#include "lex.yy.h"
#include "node.h"

int yyerror(YYLTYPE loc, char* lexer, char* msg) {
	printf("%d:%d-%d:%d: %s\n", loc.first_line, loc.first_column, loc.first_line, loc.first_column, msg);
}

int main() {
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string("a = -10.4 + -.8 - -3.7e300\n", scanner);

	// !
	YYSTYPE param;
	YYLTYPE loc;

	node* uit;
	int a = yyparse(&uit, scanner);

	printf("parse = %d\n", a);

	char* buf[1024];
	write_node(uit, buf, 1024);
	puts(buf);

	yylex_destroy(scanner);

	return 0;
}
