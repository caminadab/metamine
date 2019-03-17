%define parse.error verbose
%define api.pure true
%locations
%token-table
%glr-parser
%define api.value.type {struct node*}
%lex-param {void* scanner}

%parse-param {void** root}
%parse-param {void* scanner}

%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

	#include "node.h"

	typedef struct node* YYSTYPE;

	#define YYLTYPE_IS_DECLARED
	typedef struct YYLTYPE  
	{  
		int first_line;  
		int first_column;  
		int last_line;  
		int last_column;  
	} YYLTYPE;

	#include "lex.yy.h"
%}

%token NAAM
%token TEKST
%token DAN "=>"
%token TO "->"
%token MAPLET "-->"
%token ASS ":="
%token ISN "!="
%token INC "+="
%token CAT "||"
%token TIL ".."
%token CART "xx"
%token END 0 "invoereinde"
%token NEG '-'
%token GDGA ">="
%token ISB "~="
%token KDGA "<="
%token OUD '\''
%token TAB '\t'
%token EN "/\\"
%token OF "\\/"
%token NIET "niet"
%token JOKER "_"
%token EXOF "exof"
%token NOCH "noch"

/* %precedence NAAM TEKST */
%left "=>"
%left EN OF EXOF NOCH NIET
%left '=' "!=" "~="
%left ":=" "+=" "-=" "|=" "&="
%left '@'
%left ':'
%left "->" "-->"
%left ','
%left '<' '>' "<=" ">="
%left '&' '|'
%left "||"
%left ".."
%left "xx"
%left '+' '-'
%nonassoc CALL
%left '*' '/'
%left NEG '#'
%right '^' '_'
%left OUD
%left '.'
%nonassoc '%' '\'' INV M0 M1 M2 M3 M4 MN I0 I1 I2 I3 I4
%left NAAM TEKST

%%

input:
	exp sep { *root = $$ = $1; YYACCEPT; }
|	block { *root = $$ = $1; YYACCEPT; }
|	error { *root = $$ = a("fout"); yyerrok; YYACCEPT; }
;

block:
	exp sep exp sep { $$ = exp3(a("/\\"), $1, $3); }
|	block exp sep { $$ = append($1, $2); }
|	block error sep { $$ = append($1, a("fout")); yyerrok; }
;

/* Een of meer regeleinden */
sep: '\n' | sep '\n' ;

/*op:
	'^' | '_' | '*' | '/' | '+' | '-'
| '[' ']' | '{' '}'
| "->" | "||" | ".." | "xx" | "=>"
| '=' | "!=" | "~=" | '>' | '<' | ">=" | "<="
| '|' | '&' | '#'
| ":=" | "+=" | "-=" | "|=" | "&="
| "en" | "of" | "exof" | "noch" | "niet"
| '.' | '@' | ':' | ">>" | "<<"
;*/

single:
	NAAM 
| TEKST								{ $$ = $1; }
| single '%'					{ $$ = _exp2(a("%"), $1); }
| single '\''					{ $$ = _exp2(a("'"), $1); }
| single I0						{ $$ = _exp2($1, a("0")); }
| single I1						{ $$ = _exp2($1, a("1")); }
| single I2						{ $$ = _exp2($1, a("2")); }
| single I3						{ $$ = _exp2($1, a("3")); }
| single INV					{ $$ = _exp2(a("inverteer"), $1); }
| single M0						{ $$ = exp3(a("^"), $1, a("0")); }
| single M1						{ $$ = exp3(a("^"), $1, a("1")); }
| single M2						{ $$ = exp3(a("^"), $1, a("2")); }
| single M3						{ $$ = exp3(a("^"), $1, a("3")); }
| single M4						{ $$ = exp3(a("^"), $1, a("4")); }
| single MN						{ $$ = exp3(a("^"), $1, a("n")); }
|	'(' exp ')'					{ $$ = $2; }
| '[' list ']'				{ $$ = $2; }
| '{' set '}'					{ $$ = $2; }
| single '\'' %prec OUD	{ $$ = _exp2(a("\'"), $1); }

/*| '(' op ')'					{ $$ = $2; }*/

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

| '(' '&' ')'				{ $$ = a("|"); }
| '(' '|' ')'				{ $$ = a("&"); }
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

|	'(' error ')'				{ $$ = a("fout"); yyerrok; }
|	'[' error ']'				{ $$ = a("fout"); yyerrok; }
|	'{' error '}'				{ $$ = _exp2(a("{}"), a("fout")); yyerrok; }
;

exp:
	single
| exp '^' exp       	{ $$ = exp3(a("^"), $1, $3); }
| exp '_' exp       	{ $$ = exp3(a("_"), $1, $3); }
| exp '*' exp       	{ $$ = exp3(a("*"), $1, $3); }
| exp '/' exp       	{ $$ = exp3(a("/"), $1, $3); }
| exp '+' exp       	{ $$ = exp3(a("+"), $1, $3); }
| exp '-' exp       	{ $$ = exp3(a("-"), $1, $3); }

| exp "->" exp			{ $$ = exp3(a("->"), $1, $3); }
/*| params "->" exp			{ $$ = exp3(a("->"), $1, $3); }*/
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
| exp '|' exp				{ $$ = exp3(a("|"), $1, $3); }
| exp '&' exp				{ $$ = exp3(a("&"), $1, $3); }

| exp ":=" exp				{ $$ = exp3(a(":="), $1, $3); }
| exp "+=" exp				{ $$ = exp3(a("+="), $1, $3); }
| exp "-=" exp				{ $$ = exp3(a("-="), $1, $3); }
| exp "|=" exp				{ $$ = exp3(a("|="), $1, $3); }
| exp "&=" exp				{ $$ = exp3(a("&="), $1, $3); }

| exp "/\\" exp				{ $$ = exp3(a("/\\"), $1, $3); }
| exp "\\/" exp				{ $$ = exp3(a("\\/"), $1, $3); }
| exp "exof" exp			{ $$ = exp3(a("xof"), $1, $3); }
| exp "noch" exp			{ $$ = exp3(a("noch"), $1, $3); }
| "niet" exp					{ $$ = _exp2(a("!"), $2); }

| exp '.' exp       	{ $$ = exp3(a("."), $1, $3); }
| exp '@' exp       	{ $$ = exp3(a("@"), $1, $3); }
| exp ':' exp       	{ $$ = exp3(a(":"), $1, $3); }

| NEG exp  %prec NEG	{ $$ = _exp2(a("-"), $2); }
/*| exp '\'' %prec OUD	{ printf("HOI"); $$ = _exp2(a("'"), $1); }*/

| single single %prec CALL { $$ = _exp2($1, $2); }
| single single single %prec CALL { $$ = exp3($2, $1, $3); }
| single single single single %prec CALL { $$ = a("fout"); yyerrok; }
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
