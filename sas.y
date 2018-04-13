/* Infix notation calculator.  */

%{
  #include <math.h>
  #include <stdio.h>
	#include <string.h>
	typedef char token[0x10];
  int yylex (void);
  void yyerror (char const *);

	enum { LIT };
	token stack[0x1000];
	int sp = 0;

	void push(char* token) {
		strcpy(&stack[sp++], token);
	}

	int skip(int sp) {
		if (isalnum(*stack[sp-1]))
			return sp-1;
		else {
			sp = skip(sp-1);
			//sp = skip(sp);
			return sp-1;
		}
	}

	void yield(int sp) {
		if (isalnum(*stack[sp-1]))
			printf("%s", stack[sp-1]);
		else {
			int numops = 2;
			if (!strcmp(stack[sp-1], "_"))
				numops = 1;

			putchar('(');
			if (*stack[sp-1] == '_')
				printf("- ");
			else
				printf("%s ", stack[sp-1]);

			if (numops == 2) {
				int right = sp-1;
				int left = skip(sp-1);
				yield(left);
				putchar(' ');
				yield(right);
			}
			else if (numops == 1) {
				yield(sp-1);
			}

			putchar(')');
		}
	}
%}

/* Bison declarations.  */
%define api.value.type {char*}
%token NUM
%token NAME
%left '-' '+'
%left '*' '/'
%precedence NEG   /* negation--unary minus */
%right '^'        /* exponentiation */

%%

input:
  %empty
| input line
;

line:
  '\n'
|	eq 	{ yield(sp); putchar('\n'); }
;

eq: exp '=' exp				{ push("="); }

exp:
  NUM                { push($1); }
| exp '^' exp        { push("^"); }
| exp '*' exp        { push("*"); }
| exp '/' exp        { push("/"); }
| exp '+' exp        { push("+"); }
| exp '-' exp        { push("-"); }
| '-' exp  %prec NEG { push("_"); }
| '(' exp ')'        { push("_"); }
;
