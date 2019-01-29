#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#include "node.h"
#include "taal.h"

extern char token[0x1000];
extern char buf[0x10000];
extern const char* in;

int yylex() {
	yylval = a("fout");
	unsigned char c;

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
	if (c & 0x80) {
		uint32_t u = 0;
		// 2 bytes
		if ((c & 0xE0) == 0x6) {
			puts("2");
			u |= (c & 0x1F) << 6;
			c = *in++;
			u |= (c & 0x3F)  << 0;
		}
		
		// 3 bytes
		else if ((c & 0xF0) == 0xE0u) {
			puts("3");
			u |= (c & 0x0F) << 12;
			c = *in++;
			u |= (c & 0x3F) << 6;
			c = *in++;
			u |= (c & 0x3F) << 0;
		}

		// 4 bytes
		else if ((c & 0xF8) == 0xF0) {
			puts("4");
			u |= (c & 0x7) << 18;
			c = *in++; // byte 2
			u |= (c & 0x3F) << 12;
			c = *in++; // byte 3
			u |= (c & 0x3F) << 6;
			c = *in++; // byte 4
			u |= (c & 0x3F) << 0;
		}

		if (u == L'⁰') { strcpy(token, "^0"); return M0; }
		if (u == L'¹') { strcpy(token, "^1"); return M1; }
		if (u == L'²') { strcpy(token, "^2"); return M2; }
		if (u == L'³') { strcpy(token, "^3"); return M3; }
		if (u == L'⁴') { strcpy(token, "^4"); return M4; }
		if (u == L'₀') { strcpy(token, "_0"); return I0; }
		if (u == L'₁') { strcpy(token, "_1"); return I1; }
		if (u == L'₂') { strcpy(token, "_2"); return I2; }
		if (u == L'₃') { strcpy(token, "_3"); return I3; }
		if (u == L'₄') { strcpy(token, "_4"); return I4; }

		if (u == L'×') { strcpy(token, "xx"); return CART; }
		if (u == L'→') { strcpy(token, "->"); return TO; }
		if (u == L'⇒') { strcpy(token, "=>"); return DAN; }
		if (u == L'≈') { strcpy(token, "~="); return ISB; }
		if (u == L'≥') { strcpy(token, ">="); return GDGA; }
		if (u == L'≤') { strcpy(token, "<="); return KDGA; }
		if (u == L'≠') { strcpy(token, "!="); return ISN; }
		if (u == L'∘') { strcpy(token, "@"); return '@'; }
		if (u == L'∆') { strcpy(token, "delta"); return KWADRAAT; }
		if (u == L'τ') { strcpy(token, "tau"); return KWADRAAT; }
		if (u == L'∑' ) { strcpy(token, "som"); return NAAM; }
		if (u == L'∪' ) { strcpy(token, "unie"); return NAAM; }
		if (u == L'∩') { strcpy(token, "intersectie"); return NAAM; }
		if (u == L'∅') { strcpy(token, "niets"); return NAAM; }
		if (u == L'∧') { strcpy(token, "/\\"); return EN; }
		if (u == L'∨') { strcpy(token, "\\/"); return OF; }
		if (u == L'√') { strcpy(token, "wortel"); return NAAM; }
		if (u == L'∐') { strcpy(token, "co"); return NAAM; }
		if (u == L'∏') { strcpy(token, "dis"); return NAAM; }
		if (u == L'¬') { strcpy(token, "!"); return NAAM; }
		
		printf("ONGELDIG UNICODE TEKEN ((%x))\n", u);
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

		if (c == '|') id = '|';
		if (c == '&') id = '&';
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
