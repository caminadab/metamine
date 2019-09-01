#include "ontleed.h"
#include "node.h"
#include ".lex.yy.h"
#include ".taal.yy.h"

int yyerror(YYLTYPE* loc, void** root, struct fout* fouten, int* numfouten, int maxfouten, void* scanner, const char* yymsg) {
	// teveel fouten
	if (*numfouten >= maxfouten) {
		strcpy(fouten[*numfouten-1].msg, "teveel fouten");
		fouten[*numfouten-1].loc = *loc;
		return 1;
	}
	struct fout* fout = &fouten[*numfouten];
	fout->loc = *loc;
	strcpy(fout->msg, yymsg);

	(*numfouten)++;

	return 0;
}

int ontleed(char* code, char* buf, int buflen, struct fout* fouten, int maxfouten) {
	// invoer scanner
	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	node* wortel;

	int numfouten = 0;

	int ok = yyparse((void**)&wortel, (void*)&fouten, (void*)&numfouten, maxfouten, scanner);

	//yylex_destroy(scanner);

	write_node(wortel, buf, buflen);

	return numfouten;
}
