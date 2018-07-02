%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

	#include "node.h"

  int yylex (void);
  void yyerror (char const *);

	node* wortel;

	// fouten
	struct fout {
		int lijn;
		char wat[0x1000];
	};

	int lijn;
	int foutlen = 0;
	struct fout fouten[0x10];

	void fout(int lijn, char* bericht) {
		struct fout fout;
		fout.lijn = lijn;
		strcpy(fout.wat, bericht);
		fouten[foutlen++] = fout;
	}
%}

/* Bison declarations.  */
%define api.value.type {node*}
%token NAME
%token TO "->"
%token CAT "||"
%token TIL ".."
%token CART "xx"
%token END 0 "invoereinde"
%token NEG '-'

%left "->"
%left '<' '>' "<=" ">="
%left "||"
%left ".."
%left "xx"
%left '+' '-'
%left '*' '/'
%precedence NEG
%right '^' '_'
%left '.'

%%

input:
	%empty							{ $$ = wortel = exp0(); }
|	'\n' input					{ $$ = $2; }
/*|	input '\n'					{ $$ = $1; }*/
| input eq						{ $$ = append($1, $2); }
;

eq:
	exp '=' exp					{ $$ = exp3(a("="), $1, $3); }
|	error								{ fout(lijn, "geen vergelijking"); }
;

single:
	NAME
|	'(' exp ')'					{ $$ = $2; }
| '[' list ']'				{ $$ = $2; }
;

exp:
	single
| exp '^' exp       	{ $$ = exp3(a("^"), $1, $3); }
| exp '_' exp       	{ $$ = exp3(a("_"), $1, $3); }
| exp '*' exp       	{ $$ = exp3(a("*"), $1, $3); }
| exp '/' exp       	{ $$ = exp3(a("/"), $1, $3); }
| exp '+' exp       	{ $$ = exp3(a("+"), $1, $3); }
| exp '-' exp       	{ $$ = exp3(a("-"), $1, $3); }
| exp "->" exp				{ $$ = exp3(a("->"), $1, $3); }
| exp "||" exp				{ $$ = exp3(a("||"), $1, $3); }
| exp ".." exp				{ $$ = exp3(a(".."), $1, $3); }
| exp "xx" exp				{ $$ = exp3(a("xx"), $1, $3); }

| exp '>' exp					{ $$ = exp3(a(">"), $1, $3); }
| exp '<' exp					{ $$ = exp3(a("<"), $1, $3); }
| exp ">=" exp				{ $$ = exp3(a(">="), $1, $3); }
| exp "<=" exp				{ $$ = exp3(a("<="), $1, $3); }

| exp '.' exp       	{ $$ = exp3(a("."), $1, $3); }

| NEG exp  %prec NEG	{ $$ = _exp2(a("-"), $2); }
;

list:
	%empty							{ $$ = exp1(a("[]")); }
|	items
;

items:
	exp									{ $$ = _exp2(a("[]"), $1); }
| items ',' exp				{ $$ = append($1, $3); }
;
