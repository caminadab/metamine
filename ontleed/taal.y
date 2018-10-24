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
%glr-parser
%token NAAM
%token TEKST
%token DAN "=>"
%token TO "->"
%token ASS ":="
%token ISN "!="
%token INC "+="
%token CAT "||"
%token TIL ".."
%token CART "xx"
%token COMP '@'
%token END 0 "invoereinde"
%token NEG '-'
%token IS '='
%token ONG '='
%token GDGA ">="
%token ISB "~="
%token KDGA "<="
%token OUD '\''
%token TAB '\t'
%token EN "en"
%token OF "of"
%token NIET "niet"
%token EXOF "exof"
%token NOCH "noch"

%token DISJ '|'
%token CONJ '&'

/* %precedence NAAM TEKST */
%left "=>"
%left EN OF EXOF NOCH NIET
%left '=' "!=" "~="
%left ":=" "+=" "-=" "|=" "&="
%left '@'
%left ':'
%left "->" 
%left ','
%left '<' '>' "<=" ">="
%left '&' '|'
%left "||"
%left ".."
%left "xx"
%left '+' '-'
%nonassoc CALL
%left '*' '/'
%left NEG
%right '^' '_'
%left OUD
%left '.'
%nonassoc '%' KWADRAAT
%left NAAM TEKST

%%

input:
	%empty							{ $$ = wortel = exp0(); }
| input '\n'			
| input exp '\n'			{ $$ = append($1, $2); }
| input error '\n'		{ $$ = append($1, a("fout")); yyerrok; }
|	error '\n'					{ $$ = a("fout"); yyerrok; }
|	error 							{ $$ = a("fout"); yyerror; }
;

/*
subfeit:
	'\t' feit '\n'

subfeiten:
	%empty							{ $$ = a("{}"); }
|	subfeiten subfeit		{ $$ = append($1, $2); }
;

set:
		'{' '\n' subfeiten '\n' '}'
*/

/*	| exp '=' set					{ $$ = exp3(a("="), $1, $3); }*/
feit: exp;

single:
	NAAM 
| TEKST								{ $$ = tekst($1); }
| single '%'					{ $$ = _exp2(a("%"), $1); }
| single KWADRAAT			{ $$ = exp3(a("^"), $1, a("2")); }
|	'(' exp ')'					{ $$ = $2; }
| '[' list ']'				{ $$ = $2; }
| '{' set '}'					{ $$ = $2; }
| single '\'' %prec OUD	{ $$ = _exp2(a("\'"), $1); }

| '(' '^' ')'       	{ $$ = a("^"); }
| '(' '_' ')'       	{ $$ = a("_"); }
| '(' '*' ')'       	{ $$ = a("*"); }
| '(' '/' ')'       	{ $$ = a("/"); }
| '(' '+' ')'       	{ $$ = a("+"); }
| '(' '-' ')'       	{ $$ = a("-"); }

| '(' '[' ']' ')'     { $$ = a("[]"); }
| '(' '{' '}' ')'     { $$ = a("{}"); }

| '(' "->" ')'				{ $$ = a("->"); }
| '(' "||" ')'				{ $$ = a("||"); }
| '(' ".." ')'				{ $$ = a(".."); }
| '(' "xx" ')'				{ $$ = a("xx"); }
| '(' "=>" ')'				{ $$ = a("=>"); }

| '(' '='	')'					{ $$ = a("="); }
| '(' "!=" ')'				{ $$ = a("!="); }
| '(' "~=" ')'				{ $$ = a("~="); }
| '(' '>' ')'					{ $$ = a(">"); }
| '(' '<' ')'					{ $$ = a("<"); }
| '(' ">=" ')'				{ $$ = a(">="); }
| '(' "<=" ')'				{ $$ = a("<="); }

| '(' DISJ ')'				{ $$ = a("|"); }
| '(' CONJ ')'				{ $$ = a("&"); }
| '(' '#' ')'       	{ $$ = a("#"); }

| '(' ":=" ')'				{ $$ = a(":="); }
| '(' "+=" ')'				{ $$ = a("+="); }
| '(' "-=" ')'				{ $$ = a("-="); }
| '(' "|=" ')'				{ $$ = a("|="); }
| '(' "&=" ')'				{ $$ = a("&="); }

| '(' "en" ')'				{ $$ = a("en"); }
| '(' "of" ')'				{ $$ = a("of"); }
| '(' "exof" ')'			{ $$ = a("exof"); }
| '(' "noch" ')'			{ $$ = a("noch"); }
| '(' "niet" ')'			{ $$ = a("niet"); }

| '(' '.' ')'       	{ $$ = a("."); }
| '(' '@' ')'       	{ $$ = a("@"); }
| '(' ':' ')'       	{ $$ = a(":"); }
| '(' ">>" ')'       	{ $$ = a(">>"); }
| '(' "<<" ')'       	{ $$ = a("<<"); }

|	'(' error ')'				{ $$ = a("fout"); rapporteer(lijn, "?"); yyerrok; }
|	'[' error ']'				{ $$ = a("fout"); rapporteer(lijn, "?"); yyerrok; }
|	'{' error '}'				{ $$ = _exp2(a("{}"), a("fout")); rapporteer(lijn, "?"); yyerrok; }
;

exp:
	single
| single single %prec CALL{ $$ = _exp2($1, $2); }
| exp '^' exp       	{ $$ = exp3(a("^"), $1, $3); }
| exp '_' exp       	{ $$ = exp3(a("_"), $1, $3); }
| exp '*' exp       	{ $$ = exp3(a("*"), $1, $3); }
| exp '/' exp       	{ $$ = exp3(a("/"), $1, $3); }
| exp '+' exp       	{ $$ = exp3(a("+"), $1, $3); }
| exp '-' exp       	{ $$ = exp3(a("-"), $1, $3); }

| params "->" exp			{ $$ = exp3(a("->"), $1, $3); }
| exp "||" exp				{ $$ = exp3(a("||"), $1, $3); }
| exp ".." exp				{ $$ = exp3(a(".."), $1, $3); }
| exp "xx" exp				{ $$ = exp3(a("xx"), $1, $3); }
| exp "=>" exp				{ $$ = exp3(a("=>"), $1, $3); }

| exp '='	exp					{ $$ = exp3(a("="), $1, $3); }
| exp "!=" exp				{ $$ = exp3(a("!="), $1, $3); }
| exp "~=" exp				{ $$ = exp3(a("~="), $1, $3); }
| exp '>' exp					{ $$ = exp3(a(">"), $1, $3); }
| exp '<' exp					{ $$ = exp3(a("<"), $1, $3); }
| exp ">=" exp				{ $$ = exp3(a(">="), $1, $3); }
| exp "<=" exp				{ $$ = exp3(a("<="), $1, $3); }

| '#' exp							{ $$ = _exp2(a("#"), $2); }
| exp DISJ exp				{ $$ = exp3(a("|"), $1, $3); }
| exp CONJ exp				{ $$ = exp3(a("&"), $1, $3); }

| exp ":=" exp				{ $$ = exp3(a(":="), $1, $3); }
| exp "+=" exp				{ $$ = exp3(a("+="), $1, $3); }
| exp "-=" exp				{ $$ = exp3(a("-="), $1, $3); }
| exp "|=" exp				{ $$ = exp3(a("|="), $1, $3); }
| exp "&=" exp				{ $$ = exp3(a("&="), $1, $3); }

| exp "en" exp				{ $$ = exp3(a("en"), $1, $3); }
| exp "of" exp				{ $$ = exp3(a("of"), $1, $3); }
| exp "exof" exp			{ $$ = exp3(a("exof"), $1, $3); }
| exp "noch" exp			{ $$ = exp3(a("noch"), $1, $3); }
| "niet" exp					{ $$ = _exp2(a("niet"), $2); }

| exp '.' exp       	{ $$ = exp3(a("."), $1, $3); }
| exp '@' exp       	{ $$ = exp3(a("@"), $1, $3); }
| exp ':' exp       	{ $$ = exp3(a(":"), $1, $3); }

| NEG exp  %prec NEG	{ $$ = _exp2(a("-"), $2); }
/*| exp '\'' %prec OUD	{ printf("HOI"); $$ = _exp2(a("'"), $1); }*/

| single single single single %prec CALL	{ $$ = a("fout"); rapporteer(lijn, "?"); yyerrok; }
| single single single %prec CALL	{ $$ = exp3($2, $1, $3); }
|	'[' error ']'				
;

list:
	%empty							{ $$ = exp1(a("[]")); }
|	items
;

set:
	%empty							{ $$ = exp1(a("{}")); }
|	setitems
;

setitems:
	exp									{ $$ = _exp2(a("{}"), $1); }
| setitems ',' exp			{ $$ = append($1, $3); }
;

items:
	exp									{ $$ = _exp2(a("[]"), $1); }
| items ',' exp				{ $$ = append($1, $3); }
;

params:
	'(' exp ',' exp  ')'				{ $$ = exp3(a(","), $2, $4); }
|	exp ',' exp 			 					{ $$ = exp3(a(","), $1, $3); }
|	single											{ $$ = $1; }
/*|	params ',' NAAM			{ $$ = append($1, $3); } */
;
