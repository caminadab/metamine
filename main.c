#include <stdio.h>

char token[0x10];
extern char* yylval;
extern char stack[0x10][0x1000];
extern int sp;
#define NUM 258

void yyerror (char const * s) {
	fprintf(stderr, "%s\n", s);
}

int yylex (void) {
	int c;

	// wit overslaan
	while (1) {
		while ((c = getchar ()) == ' ' || c == '\t')
			continue;
		while (c == ';') {
			while ((c = getchar()) != '\n')
				continue;
			c = getchar();
		}
		if (c != ' ' && c != '\t' && c != ';')
			break;
	}

	// tokens
	if (isalnum(c)) {
		int i;
		for (i = 0; i < 0x10 && isalnum(c); i++) {
			token[i] = c;
			c = getchar();
		}
		ungetc(c, stdin);
		token[i] = 0;
		yylval = token;
		return NUM;
	}

	// klaar
	if (c == EOF)
		return 0;

	// token
	token[0] = c;
	token[1] = 0;
	yylval = token;
	return c;
}

int main(void) {
	puts("(");
	int a = yyparse();
	if (a) return a;
	puts(")");
}

