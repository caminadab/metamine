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

char* itoa(int value, char* str, int base) {
	const char* cijfers = "0123456789abcdefghijklmnopqrstuvwxyz";
	char buf[65];
	int len = 0;
	while (value) {
		buf[len++] = cijfers[value % base];
		value /= 10;
	}

	// nu keer om
	for (int i = 0; i < len; i++) {
		str[i] = buf[len-i-1];
	}

	str[len] = '\0';

	return str;
}

int yylex() {
	yylval = a("fout");
	unsigned char c;

	// wit overslaan
	while (1) {
		while ((c = *in++) == ' ' || c == '\t')
			continue;
		while (c == ';') {
			// lang
			if (*in == '-') {
				while (*in && !(*in == '-' && *(in+1) == ';'))
					in ++;
				in ++;
				c = *in++;
			}
			// kort
			else {
				while ((c = *in++) != '\n')
					continue;
				c = *in++;
			}
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
		if ((c & 0xE0) == 0xC0u) {
			u |= (c & 0x1Fu) << 6;
			c = *in++;
			u |= (c & 0x3Fu)  << 0;
		}
		
		// 3 bytes
		else if ((c & 0xF0) == 0xE0u) {
			u |= (c & 0x0F) << 12;
			c = *in++;
			u |= (c & 0x3F) << 6;
			c = *in++;
			u |= (c & 0x3F) << 0;
		}

		// 4 bytes
		else if ((c & 0xF8) == 0xF0u) {
			u |= (c & 0x7) << 18;
			c = *in++; // byte 2
			u |= (c & 0x3F) << 12;
			c = *in++; // byte 3
			u |= (c & 0x3F) << 6;
			c = *in++; // byte 4
			u |= (c & 0x3F) << 0;
		}

		// + 2 om de ¹ te skippen
		if (u == L'⁻') { in += 2; yylval = a(strcpy(token, "^-1")); return INV; }
		if (u == L'⁰') { yylval = a(strcpy(token, "^0")); return M0; }
		if (u == L'¹') { yylval = a(strcpy(token, "^1")); return M1; }
		if (u == L'²') { yylval = a(strcpy(token, "^2")); return M2; }
		if (u == L'³') { yylval = a(strcpy(token, "^3")); return M3; }
		if (u == L'⁴') { yylval = a(strcpy(token, "^4")); return M4; }
		if (u == L'ⁿ') { yylval = a(strcpy(token, "^n")); return MN; }
		if (u == L'₀') { yylval = a(strcpy(token, "_0")); return I0; }
		if (u == L'₁') { yylval = a(strcpy(token, "_1")); return I1; }
		if (u == L'₂') { yylval = a(strcpy(token, "_2")); return I2; }
		if (u == L'₃') { yylval = a(strcpy(token, "_3")); return I3; }
		if (u == L'₄') { yylval = a(strcpy(token, "_4")); return I4; }

		if (u == L'×') { yylval = a(strcpy(token, "xx")); return CART; }
		if (u == L'→') { yylval = a(strcpy(token, "->")); return TO; }
		if (u == L'↦') { yylval = a(strcpy(token, "-->")); return MAPLET; }
		if (u == L'⇒') { yylval = a(strcpy(token, "=>")); return DAN; }
		if (u == L'≈') { yylval = a(strcpy(token, "~=")); return ISB; }
		if (u == L'≥') { yylval = a(strcpy(token, ">=")); return GDGA; }
		if (u == L'≤') { yylval = a(strcpy(token, "<=")); return KDGA; }
		if (u == L'≠') { yylval = a(strcpy(token, "!=")); return ISN; }
		if (u == L'∘') { yylval = a(strcpy(token, "@")); return '@'; }
		if (u == L'∆') { yylval = a(strcpy(token, "delta")); return NAAM; }
		if (u == L'τ') { yylval = a(strcpy(token, "tau")); return NAAM; }
		if (u == L'∞') { yylval = a(strcpy(token, "oneindig")); return NAAM; }
		if (u == L'∑' ) { yylval = a(strcpy(token, "som")); return NAAM; }
		if (u == L'∪' ) { yylval = a(strcpy(token, "unie")); return NAAM; }
		if (u == L'∩') { yylval = a(strcpy(token, "intersectie")); return NAAM; }
		if (u == L'∅') { yylval = a(strcpy(token, "niets")); return NAAM; }
		if (u == L'∧') { yylval = a(strcpy(token, "/\\")); return EN; }
		if (u == L'∨') { yylval = a(strcpy(token, "\\/")); return OF; }
		if (u == L'√') { yylval = a(strcpy(token, "wortel")); return NAAM; }
		if (u == L'∐') { yylval = a(strcpy(token, "co")); return NAAM; }
		if (u == L'∏') { yylval = a(strcpy(token, "prod")); return NAAM; }
		if (u == L'¬') { yylval = a(strcpy(token, "!")); return NIET; }
		if (u == L'·') { yylval = a(strcpy(token, "*")); return '*'; }
		if (u == L'★') { yylval = a(strcpy(token, "_")); return NAAM; }
		if (u == L'☆') { yylval = a(strcpy(token, "__")); return NAAM; }
		if (u == L'ℝ') { yylval = a(strcpy(token, "getal")); return NAAM; }
		if (u == L'ℕ') { yylval = a(strcpy(token, "nat")); return NAAM; }
		if (u == L'ℤ') { yylval = a(strcpy(token, "int")); return NAAM; }
		
		printf("ONGELDIG UNICODE TEKEN ((%x))\n", u);
	}

	// fuck it, karakter
	if (c == '\'') {
		c = *in++; // karakter
		// geen unicode!
		itoa(c, token, 10);
		yylval = a(token);
		printf("TOKEN %d %s\n", c, token);
		c = *in++; // sluithaak
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
