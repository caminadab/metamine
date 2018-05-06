#include <stdio.h>

typedef struct {
	char data[0x100];
	struct node* kid;
	struct node* next;
} node;

node* a(char* t);
extern node* yylval;

#define NUM 258
//#define CAT 300

void yyerror (char const * s) {
	fprintf(stderr, "%s\n", s);
}

char token[0x100];

int yylex(void) {
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
		for (i = 0; i < 0x10 && (isalnum(c) || c == '-'); i++) {
			token[i] = c;
			c = getchar();
		}
		ungetc(c, stdin);
		token[i] = 0;
		yylval = a(token);
		return NUM;
	}

	// klaar
	if (c == EOF)
		return 0;

	// token
	/*if (c == '|') {
		int c = getchar();
		if (c == '|') {
			yylval = a("||");
			return CAT;
		} else {
			ungetc(c,stdin);
		}
	}*/

	token[0] = c;
	token[1] = 0;
	yylval = a(token);
	return c;
}

int main(void) {
	puts("(");
	int a = yyparse();
	if (a) return a;
	puts(")");
}
