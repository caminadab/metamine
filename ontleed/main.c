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

int yylex(void) {
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

	// naam
	if (isalnum(c)) {
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

	// klaar
	if (!c)
		return 0;

	if (c == '\n')
		lijn++;

	// multi-symbool
	int id;
	if (!memcmp(cc, "->", 2))				{ strcpy(token, "->"); in++; id = TO; }
	else if (!memcmp(cc, "||", 2))	{ strcpy(token, "||"); in++; id = CAT; }
	else if (!memcmp(cc, "..", 2))	{ strcpy(token, ".."); in++; id = TIL; }
	else if (!memcmp(cc, "xx", 2))	{ strcpy(token, "xx"); in++; id = CART; }
	else {
		token[0] = c;
		token[1] = 0;
		id = c;
	}
	
	yylval = a(token);
	return id;
}

char* ontleed(char* code) {
	in = code;
	yyparse();
	int len = write_node(wortel, buf, 0x1000);
	return buf;
}

int main() {
	strcpy(buf, "f = x -> x");
	in = buf;
	yyparse();
	char out[1024];
	int len = write_node(wortel, out, 0x400);
	write(1, out, len);
	return 0;
}
