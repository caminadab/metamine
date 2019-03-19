#include "taal.yy.h"
#include "lex.yy.h"
#include "node.h"

int yyerror(YYLTYPE* loc, void** root, void* scanner, const char* yymsg) {
	print_loc(*loc);
	printf(": %s\n", yymsg);
}

char BRON[] = "a = 10\nuit = [a, b]\ngraag + 1 = 3\n"; 

int main() {
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(BRON, scanner);

	// !
	YYSTYPE param;
	YYLTYPE loc;

	node* uit;
	int a = yyparse(&uit, scanner);

	printf("%s\n", BRON);
	print_node(uit);

	yylex_destroy(scanner);

	return 0;
}
