#include <stdio.h>

extern double yylval;
#define NUM 258

void yyerror (char const * s) {
	fprintf(stderr, "%s\n", s);
}

int main(void) {
	return yyparse();
}

int yylex (void)
{
	int c;

	/* Skip white space.  */
	while ((c = getchar ()) == ' ' || c == '\t')
		continue;

	/* Process numbers.  */
	if (c == '.' || isdigit (c))
	{
		ungetc (c, stdin);
		scanf ("%lf", &yylval);
		return NUM;
	}

	/* Return end-of-input.  */
	if (c == EOF)
		return 0;
	/* Return a single char.  */
	return c;
}
