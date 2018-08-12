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

int yylex() {
	int c;

	// wit overslaan
	while (1) {
		while ((c = *in++) == ' ' || c == '\t')
			continue;
		while (c == ';') {
			while ((c = *in++) != '\n')
				continue;
			lijn++;
			c = *in++;
		}
		if (c != ' ' && c != '\t' && c != ';')
			break;
	}

	const char* cc = in - 1;

	// ass
	if (c == '\'') {
		token[0] = '\'';
		token[1] = 0;
		yylval = a(token);
		return ASS;
	}

	// tab
	if (c == '\t') {
		token[0] = '\t';
		token[1] = 0;
		yylval = a(token);
		return TAB;
	}

	// klaar
	if (!c)
		return 0;

	if (c == '\n')
		lijn++;

	// multi-symbool
	int id;
			 if (!memcmp(cc, "->", 2))	{ strcpy(token, "->"); in++; id = TO; }
	else if (!memcmp(cc, "||", 2))	{ strcpy(token, "||"); in++; id = CAT; }
	else if (!memcmp(cc, "..", 2))	{ strcpy(token, ".."); in++; id = TIL; }
	else if (!memcmp(cc, "xx", 2))	{ strcpy(token, "xx"); in++; id = CART; }
	else if (!memcmp(cc, "=>", 2))	{ strcpy(token, "=>"); in++; id = DAN; }
	else if (!memcmp(cc, ":=", 2))	{ strcpy(token, ":="); in++; id = ASS; }
	else if (!memcmp(cc, "+=", 2))	{ strcpy(token, "+="); in++; id = INC; }
	else if (!memcmp(cc, "en", 2))	{ strcpy(token, "en"); in++; id = EN; }
	else if (!memcmp(cc, "of", 2))	{ strcpy(token, "of"); in++; id = OF; }
	else if (!memcmp(cc, "niet", 4))	{ strcpy(token, "niet"); in++; id = EXOF; }
	else if (!memcmp(cc, "exof", 4))	{ strcpy(token, "exof"); in++; id = EXOF; }
	else if (!memcmp(cc, "noch", 4))	{ strcpy(token, "noch"); in++; id = NOCH; }
	else if (!isalnum(c)) {
		token[0] = c;
		token[1] = 0;
		id = c;
	}

	// naam
	else if (isalnum(c)) {
		int i;
		for (i = 0; i < 0x1000 && (isalnum(c) || c == '-'); i++) {
			token[i] = c;
			c = *in++;
		}
		in--;
		token[i] = 0;
		yylval = a(token);
		return NAME;
	}

	
	yylval = a(token);
	return id;
}

char* ontleed(char* code) {
	yyreset();
	in = code;
	yyparse();
	int len = write_node(wortel, buf, 0x1000);
	return buf;
}

void test();

int main() {
	test();
	puts("klaar");
	return 0;
}
