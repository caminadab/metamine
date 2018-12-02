#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>

#include "node.h"
#include "taal.h"

extern char token[0x1000];
extern char buf[0x10000];
extern const char* in;

int yylex() {
	yylval = a("fout");
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

	// unicode oeps
	// ²
	if (c == 0xC2) {
		int ch0 = *in++;
		if (ch0 == 0xB2)
			strcpy(token, "^2");
		return KWADRAAT;
	}
	else if (c == 0xC3) {
		int ch0 = *in++;
		if (ch0 == 0x97)
			yylval = a("xx");
		return NAAM;
	}
	else if (c == 0xCF) {
		int ch0 = *in++;
		if (ch0 == 0x84)
			yylval = a("tau");
		return NAAM;
	}
			
	else if (c == 0xE2) {
		int ch0 = *in++;
		int ch1 = *in++;
		if (ch0 == 0x86 && ch1 == 0x92) {
			strcpy(token, "->");
			return TO;
		}
		else if (ch0 == 0x87 && ch1 == 0x92) {
			strcpy(token, "=>");
			return DAN;
		}
		else if (ch0 == 0x89 && ch1 == 0x88) {
			strcpy(token, "~=");
			return ISB;
		}
		else if (ch0 == 0x89 && ch1 == 0xA0) {
			strcpy(token, ">=");
			return GDGA;
		}
		else if (ch0 == 0x89 && ch1 == 0xA5) {
			strcpy(token, "<=");
			return KDGA;
		}
		else if (ch0 == 0x89 && ch1 == 0xA4) {
			strcpy(token, "!=");
			return ISN;
		}
		else if (ch0 == 0x88 && ch1 == 0x98) {
			strcpy(token, "@");
			return '@';
		}
		else if (ch0 == 0x88) {
			if (ch1 == 0xAA)
				yylval = a("unie");
			else if (ch1 == 0xA9)
				yylval = a("intersectie");
			else if (ch1 == 0x91)
				yylval = a("som");
		}
		return NAAM;
	}

	// tekst
	if (c == '"') {
		int i = 0;
		// begin
		token[i++] = c;
		c = *in++;
		while (c != '"' && c) {
			token[i++] = c;
			c = *in++;
		}
		// eind
		token[i++] = c;
		// sluiter
		token[i++] = 0;
		yylval = a(token);
		return TEKST;
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
		return NAAM;
	}

	
	yylval = a(token);
	return id;
}
