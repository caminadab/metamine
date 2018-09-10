#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>

#include "node.h"
#include "taal.h"
#include "global.h"

extern node* yylval;

struct fout fouten[0x10];

char token[0x100];
char buf[0x1000];
const char* in;

void rapporteer(int lijn, char* bericht);
int yylex();
void yyerror (char const * s) {
	//fprintf(stderr, "%s\n", s);
}

void yyreset() {
	memset(buf, 0, sizeof(buf));
	in = buf;
	lijn = 0;
	foutlen = 0;
	numnodes = 0;
	wortel = 0;
}

char* ontleed(char* code) {
	yyreset();
	in = code;
	yyparse();
	if (!wortel) {
		strcpy(buf, "fout");
		return buf;
	}
	int len = write_node(wortel, buf, 0x1000);
	return buf;
}

void test();

int main() {
	test();
	puts("klaar");
	return 0;
}
