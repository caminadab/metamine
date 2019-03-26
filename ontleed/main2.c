#include "taal.yy.h"
#include "lex.yy.h"
#include "node.h"

int yyerror(YYLTYPE* loc, void** root, void* scanner, const char* yymsg) {
	print_loc(*loc);
	printf(": %s\n", yymsg);
}

char BRON[] = "s =    Σ  ( (1 .. 1000) waarvoor (i → ★mod3=0 ∧ ★mod5=0) )\n uit = tekst s\n";

int main() {
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(BRON, scanner);

	// !
	YYSTYPE param;
	YYLTYPE loc;

	node* uit;
	int a = yyparse(&uit, scanner);

	print_node(uit);

	yylex_destroy(scanner);

	return 0;
}
