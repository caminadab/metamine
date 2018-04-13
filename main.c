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

	/* Skip white space.  */
	while ((c = getchar ()) == ' ' || c == '\t')
		continue;

	/* Process numbers.  */
	if (isalnum(c)) {
		int i;
		for (i = 0; i < 0x10 && isalnum(c); i++) {
			token[i] = c;
			c = getchar();
			yylval = token;
		}
		token[i] = 0;
		return NUM;
	}

	/* Return end-of-input.  */
	if (c == EOF)
		return 0;
	/* Return a single char.  */
	token[0] = c;
	token[1] = 0;
	yylval = token;
	return c;
}

int main(void) {
	printf("(");
	int a = yyparse();
	if (a) return a;
	printf(")");

	//puts(stack[3]);
}

