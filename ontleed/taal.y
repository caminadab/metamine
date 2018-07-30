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
		char bericht[0x1000];
	};

	int lijn;
	int foutlen = 0;
	struct fout fouten[0x10];

	void rapporteer(int lijn, char* bericht) {
		struct fout fout;
		fout.lijn = lijn;
		strcpy(fout.bericht, bericht);
		fouten[foutlen++] = fout;
	}
%}

/* Bison declarations.  */
%define api.value.type {node*}
%token NAME
%token DAN "=>"
%token TO "->"
%token ASS ":="
%token CAT "||"
%token TIL ".."
%token CART "xx"
%token END 0 "invoereinde"
%token NEG '-'
%token IS '='
%token DELTA '\''
%token EN "en"
%token OF "of"
%token EXOF "exof"
%token NOCH "noch"

%left "=>"
%left '='
%left "en" "of" "exof" "noch"
%left "->"
%left '<' '>' "<=" ">="
%left "||"
%left ".."
%left "xx"
%left '+' '-'
%left '*' '/'
%precedence NEG
%right '^' '_'
%left DELTA
%left '.'

%%

input:
	%empty							{ $$ = wortel = exp0(); }
|	'\n' input					{ $$ = $2; }
|	input '\n'					{ $$ = $1; }
| input feit					{ $$ = append($1, $2); }
|	error '\n'					{ rapporteer(lijn, "ongeldige vergelijking"); yyerrok; }
|	error 							{ rapporteer(lijn, "onherkend"); yyerror; }
;

feit:
		exp "=>" exp				{ $$ = exp3(a("=>"), $1, $3); }
	|	exp '=' exp					{ $$ = exp3(a("="), $1, $3); }
	|	exp ":=" exp				{ $$ = exp3(a(":="), $1, $3); }
	| exp ':' exp					{ $$ = exp3(a(":"), $1, $3); }
;

single:
	NAME
|	'(' exp ')'					{ $$ = $2; }
| '[' list ']'				{ $$ = $2; }

|	'(' error ')'				{ $$ = a("fout"); rapporteer(lijn, "?"); yyerrok; }
|	'[' error ']'				{ $$ = a("fout"); rapporteer(lijn, "?"); yyerrok; }
;

exp:
	single
| exp '\'' %prec DELTA						{ printf("HOI"); $$ = _exp2(a("'"), $1); }
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

| exp '='	exp					{ $$ = exp3(a("="), $1, $3); }
| exp '>' exp					{ $$ = exp3(a(">"), $1, $3); }
| exp '<' exp					{ $$ = exp3(a("<"), $1, $3); }
| exp ">=" exp				{ $$ = exp3(a(">="), $1, $3); }
| exp "<=" exp				{ $$ = exp3(a("<="), $1, $3); }

| exp "en" exp				{ $$ = exp3(a("en"), $1, $3); }
| exp "of" exp				{ $$ = exp3(a("of"), $1, $3); }
| exp "exof" exp			{ $$ = exp3(a("exof"), $1, $3); }
| exp "noch" exp			{ $$ = exp3(a("noch"), $1, $3); }

| exp "=>" exp				{ $$ = exp3(a("=>"), $1, $3); }

| exp '.' exp       	{ $$ = exp3(a("."), $1, $3); }

| NEG exp  %prec NEG	{ $$ = _exp2(a("-"), $2); }

| single single %prec NEG				{ $$ = _exp2($1, $2); }
;

list:
	%empty							{ $$ = exp1(a("[]")); }
|	items
;

items:
	exp									{ $$ = _exp2(a("[]"), $1); }
| items ',' exp				{ $$ = append($1, $3); }
;
