#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>

#include "node.h"
#include "taal.h"

extern char token[0x100];
extern char buf[0x1000];
extern const char* in;

int yylex() {
	int c;

	// wit overslaan
	while (1) {
		while ((c = *in++) == ' ' || c == '\t')
			continue;
		while (c == ';') {
			while ((c = *in++) != '\n')
				continue;
			c = *in++;
		}
		if (c != ' ' && c != '\t' && c != ';')
			break;
	}

	const char* cc = in - 1;

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

	// multi-symbool
	int id;
			 if (!memcmp(cc, "->", 2))	{ strcpy(token, "->"); in++; id = TO; }
	else if (!memcmp(cc, "||", 2))	{ strcpy(token, "||"); in++; id = CAT; }
	else if (!memcmp(cc, "..", 2))	{ strcpy(token, ".."); in++; id = TIL; }
	else if (!memcmp(cc, "xx", 2))	{ strcpy(token, "xx"); in++; id = CART; }
	else if (!memcmp(cc, ">=", 2))	{ strcpy(token, ">="); in++; id = GDGA; }
	else if (!memcmp(cc, "<=", 2))	{ strcpy(token, "<="); in++; id = KDGA; }
	else if (!memcmp(cc, "=>", 2))	{ strcpy(token, "=>"); in++; id = DAN; }
	else if (!memcmp(cc, ":=", 2))	{ strcpy(token, ":="); in++; id = ASS; }
	else if (!memcmp(cc, "+=", 2))	{ strcpy(token, "+="); in++; id = INC; }
	else if (!memcmp(cc, "en", 2))	{ strcpy(token, "en"); in++; id = EN; }
	else if (!memcmp(cc, "of", 2))	{ strcpy(token, "of"); in++; id = OF; }
	else if (!memcmp(cc, "niet", 4))	{ strcpy(token, "niet"); in+=3; id = NIET; }
	else if (!memcmp(cc, "exof", 4))	{ strcpy(token, "exof"); in+=3; id = EXOF; }
	else if (!memcmp(cc, "noch", 4))	{ strcpy(token, "noch"); in+=3; id = NOCH; }
	else if (!isalnum(c)) {
		token[0] = c;
		token[1] = 0;
		id = c;

		if (c == '|') id = DISJ;
		if (c == '&') id = CONJ;
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
