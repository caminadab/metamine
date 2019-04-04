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

	typedef struct node* YYSTYPE;

	#define YYLTYPE_IS_DECLARED
	typedef struct YYLTYPE  
	{  
		int first_line;  
		int first_column;  
		int last_line;  
		int last_column;  
	} YYLTYPE;

	#include "node.h"

	#include "lex.yy.h"

	int yyerror(YYLTYPE* loc, void** root, void* scanner, const char* yymsg);

	//#define fn3loc(a,b,c,l) exp3(a, b, c)
%}

%token NAAM
%token TEKST
%token NIN "!:"
%token SOM
%token DAN "=>"
%token TO "->"
%token MAPLET "-->"
%token ASS ":="
%token ISN "!="
%token INC "+="
%token CAT "||"
%token ICAT "::"
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
%left SOM
%left EN OF EXOF NOCH NIET
%left '=' "!=" "~="
%left ":=" "+=" "-=" "|=" "&="
%left '@'
%left ':' "!:"
%left "->" "-->"
%left ','
%left '<' '>' "<=" ">="
%left '&' '|'
%left "||" "::"
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
|	exp sep { *root = $$ = $1; YYACCEPT; }
|	error sep { *root = $$ = metfout(aloc("fout", yylloc), "onzinregel"); YYACCEPT; }
| sep exp sep { *root = $$ = $2; YYACCEPT; }
|	block { *root = $$ = $1; YYACCEPT; }
|	error { *root = $$ = metfout(aloc("fout",yylloc), "onzincode"); yyerrok; YYACCEPT; }
;

block:
	exp sep exp sep { $$ = fn3loc(aloc("/\\",yylloc), $1, $3, yylloc); }
|	sep exp sep exp sep { $$ = fn3loc(aloc("/\\",yylloc), $2, $4, yylloc); }
|	block exp sep { $$ = appendloc($1, $2, yylloc); }
|	block error sep { $$ = appendloc($1, aloc("fout", yylloc), yylloc); yyerrok; }
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
| '.' | '@' | ':' | '!:' | ">>" | "<<"
;*/
/*
/a("alocf)i,yylloc
/fn3loc(f(ilocf)i,yylloc
/exp3(f(ilocl%i,yy€kb€kb yylloc
*/

single:
	NAAM 								{ $$ = metloc($1, yylloc); }
| TEKST								{ $$ = metloc($1, yylloc); }
| single '%'					{ $$ = fn2loc(aloc("%",yylloc), $1, yylloc); }
| single '!'					{ $$ = fn2loc(aloc("faculteit",yylloc), $1, yylloc); }
| single '\''					{ $$ = fn2loc(aloc("'",yylloc), $1, yylloc); }
| single I0						{ $$ = fn2loc($1, aloc("0",yylloc), yylloc); }
| single I1						{ $$ = fn2loc($1, aloc("1",yylloc), yylloc); }
| single I2						{ $$ = fn2loc($1, aloc("2",yylloc), yylloc); }
| single I3						{ $$ = fn2loc($1, aloc("3",yylloc), yylloc); }
| single INV					{ $$ = fn2loc(aloc("inverteer",yylloc), $1, yylloc); }
| single M0						{ $$ = fn3loc(aloc("^",yylloc), $1, aloc("0",yylloc), yylloc); }
| single M1						{ $$ = fn3loc(aloc("^",yylloc), $1, aloc("1",yylloc), yylloc); }
| single M2						{ $$ = fn3loc(aloc("^",yylloc), $1, aloc("2",yylloc), yylloc); }
| single M3						{ $$ = fn3loc(aloc("^",yylloc), $1, aloc("3",yylloc), yylloc); }
| single M4						{ $$ = fn3loc(aloc("^",yylloc), $1, aloc("4",yylloc), yylloc); }
| single MN						{ $$ = fn3loc(aloc("^",yylloc), $1, aloc("n",yylloc), yylloc); }
|	'(' exp ')'					{ $$ = metloc($2, yylloc); }
| '(' exp ',' exp ')'	{ $$ = fn3loc(aloc(",",yylloc), $2, $4, yylloc); }
| '(' exp ',' exp ',' exp ')'	{ $$ = fn4loc(aloc(",",yylloc), $2, $4, $6, yylloc); }
| '(' exp ',' exp ',' exp ',' exp ')'	{ $$ = fn5loc(aloc(",",yylloc), $2, $4, $6, $8, yylloc); }
| '[' list ']'				{ $$ = metloc($2, yylloc); }
| '{' set '}'					{ $$ = metloc($2, yylloc); }

/*| '(' op ')'					{ $$ = $2; }*/

| '(' '^' ')'       	{ $$ = aloc("^",yylloc); }
| '(' '_' ')'       	{ $$ = aloc("_",yylloc); }
| '(' '*' ')'       	{ $$ = aloc("*",yylloc); }
| '(' '/' ')'       	{ $$ = aloc("/",yylloc); }
| '(' '+' ')'       	{ $$ = aloc("+",yylloc); }
| '(' '-' ')'       	{ $$ = aloc("-",yylloc); }

| '(' '[' ')'     { $$ = aloc("[]",yylloc); }
| '(' '{' '}' ')'     { $$ = aloc("{}",yylloc); }

| '(' "->" ')'				{ $$ = aloc("->",yylloc); }
| '(' "||" ')'				{ $$ = aloc("||",yylloc); }
| '(' "::" ')'				{ $$ = aloc("::",yylloc); }
| '(' ".." ')'				{ $$ = aloc("..",yylloc); }
| '(' "xx" ')'				{ $$ = aloc("xx",yylloc); }
| '(' "=>" ')'				{ $$ = aloc("=>",yylloc); }

| '(' '='	')'					{ $$ = aloc("=",yylloc); }
| '(' "!=" ')'				{ $$ = aloc("!=",yylloc); }
| '(' "~=" ')'				{ $$ = aloc("~=",yylloc); }
| '(' '>' ')'					{ $$ = aloc(">",yylloc); }
| '(' '<' ')'					{ $$ = aloc("<",yylloc); }
| '(' ">=" ')'				{ $$ = aloc(">=",yylloc); }
| '(' "<=" ')'				{ $$ = aloc("<=",yylloc); }

| '(' '&' ')'				{ $$ = aloc("|",yylloc); }
| '(' '|' ')'				{ $$ = aloc("&",yylloc); }
| '(' '#' ')'       	{ $$ = aloc("#",yylloc); }

| '(' ":=" ')'				{ $$ = aloc(":=",yylloc); }
| '(' "+=" ')'				{ $$ = aloc("+=",yylloc); }
| '(' "-=" ')'				{ $$ = aloc("-=",yylloc); }
| '(' "|=" ')'				{ $$ = aloc("|=",yylloc); }
| '(' "&=" ')'				{ $$ = aloc("&=",yylloc); }

| '(' "/\\" ')'				{ $$ = aloc("/\\",yylloc); }

| '(' "en" ')'				{ $$ = aloc("en",yylloc); }
| '(' "of" ')'				{ $$ = aloc("of",yylloc); }
| '(' "exof" ')'			{ $$ = aloc("exof",yylloc); }
| '(' "noch" ')'			{ $$ = aloc("noch",yylloc); }
| '(' "niet" ')'			{ $$ = aloc("niet",yylloc); }

| '(' '.' ')'       	{ $$ = aloc(".",yylloc); }
| '(' '@' ')'       	{ $$ = aloc("@",yylloc); }
| '(' ':' ')'       	{ $$ = aloc(":",yylloc); }
| '(' '!:' ')'       	{ $$ = aloc("!:",yylloc); }
| '(' ">>" ')'       	{ $$ = aloc(">>",yylloc); }
| '(' "<<" ')'       	{ $$ = aloc("<<",yylloc); }

|	'(' error ')'				{ $$ = aloc("fout",yylloc); yyerrok; }
|	'[' error ']'				{ $$ = aloc("fout",yylloc); yyerrok; }
|	'{' error '}'				{ $$ = fn2loc(aloc("{}",yylloc), aloc("fout",yylloc), yylloc); yyerrok; }
;

exp:
	single							{ $$ = metloc($1, yylloc); }
| exp '^' exp       	{ $$ = fn3loc(aloc("^",yylloc), $1, $3, yylloc); }
| exp '_' exp       	{ $$ = fn3loc(aloc("_",yylloc), $1, $3, yylloc); }
| exp '*' exp       	{ $$ = fn3loc(aloc("*",yylloc), $1, $3, yylloc); }
| exp '/' exp       	{ $$ = fn3loc(aloc("/",yylloc), $1, $3, yylloc); }
| exp '+' exp       	{ $$ = fn3loc(aloc("+",yylloc), $1, $3, yylloc); }
| exp '-' exp       	{ $$ = fn3loc(aloc("-",yylloc), $1, $3, yylloc); }

| SOM exp			       	{ $$ = fn2loc(aloc("som",yylloc), $2, yylloc); }
| exp "->" exp				{ $$ = fn3loc(aloc("->",yylloc), $1, $3, yylloc); }
/*| params "->" exp			{ $$ = fn3loc(aloc("->",yylloc), $1, $3, yylloc); }*/
| exp "||" exp				{ $$ = fn3loc(aloc("||",yylloc), $1, $3, yylloc); }
| exp "::" exp				{ $$ = fn3loc(aloc("::",yylloc), $1, $3, yylloc); }
| exp ".." exp				{ $$ = fn3loc(aloc("..",yylloc), $1, $3, yylloc); }
| exp "xx" exp				{ $$ = fn3loc(aloc("xx",yylloc), $1, $3, yylloc); }
| exp "=>" exp				{ $$ = fn3loc(aloc("=>",yylloc), $1, $3, yylloc); }

| exp '=' error '\n'				{ $$ = fn3loc(aloc("=",yylloc), $1, metfout(aloc("fout", yylloc), "rechterkant van vergelijking mist"), yylloc); yyerrok; }
| exp '='	exp					{ $$ = fn3loc(aloc("=",yylloc), $1, $3, yylloc); }
| exp "!=" exp				{ $$ = fn3loc(aloc("!=",yylloc), $1, $3, yylloc); }
| exp "~=" exp				{ $$ = fn3loc(aloc("~=",yylloc), $1, $3, yylloc); }
| exp '>' exp					{ $$ = fn3loc(aloc(">",yylloc), $1, $3, yylloc); }
| exp '<' exp					{ $$ = fn3loc(aloc("<",yylloc), $1, $3, yylloc); }
| exp ">=" exp				{ $$ = fn3loc(aloc(">=",yylloc), $1, $3, yylloc); }
| exp "<=" exp				{ $$ = fn3loc(aloc("<=",yylloc), $1, $3, yylloc); }

| '#' exp							{ $$ = fn2loc(aloc("#",yylloc), $2, yylloc); }
| exp '|' exp				{ $$ = fn3loc(aloc("|",yylloc), $1, $3, yylloc); }
| exp '&' exp				{ $$ = fn3loc(aloc("&",yylloc), $1, $3, yylloc); }

| exp ":=" exp				{ $$ = fn3loc(aloc(":=",yylloc), $1, $3, yylloc); }
| exp "+=" exp				{ $$ = fn3loc(aloc("+=",yylloc), $1, $3, yylloc); }
| exp "-=" exp				{ $$ = fn3loc(aloc("-=",yylloc), $1, $3, yylloc); }
| exp "|=" exp				{ $$ = fn3loc(aloc("|=",yylloc), $1, $3, yylloc); }
| exp "&=" exp				{ $$ = fn3loc(aloc("&=",yylloc), $1, $3, yylloc); }

| exp "/\\" exp				{ $$ = fn3loc(aloc("/\\",yylloc), $1, $3, yylloc); }
| exp "\\/" exp				{ $$ = fn3loc(aloc("\\/",yylloc), $1, $3, yylloc); }
| exp "exof" exp			{ $$ = fn3loc(aloc("xof",yylloc), $1, $3, yylloc); }
| exp "noch" exp			{ $$ = fn3loc(aloc("noch",yylloc), $1, $3, yylloc); }
| "niet" exp					{ $$ = fn2loc(aloc("!",yylloc), $2, yylloc); }

| exp '.' exp       	{ $$ = fn3loc(aloc(".",yylloc), $1, $3, yylloc); }
| exp '@' exp       	{ $$ = fn3loc(aloc("@",yylloc), $1, $3, yylloc); }
| exp ':' exp       	{ $$ = fn3loc(aloc(":",yylloc), $1, $3, yylloc); }
| exp "!:" exp       	{ $$ = fn2loc(aloc("!",yylloc), fn3loc(aloc(":",yylloc), $1, $3, yylloc), yylloc); } // !(:(a b))

| '-' exp  %prec NEG	{ $$ = fn2loc(aloc("-",yylloc), $2, yylloc); }

| single single %prec CALL { $$ = fn2loc($1, $2, yylloc); }
| single single single %prec CALL { $$ = fn3loc($2, $1, $3, yylloc); }
| single single single single %prec CALL { $$ = aloc("fout",yylloc); yyerrok; }
|	'[' error ']'				
;

list:
	%empty							{ $$ = exp1(aloc("[]",yylloc)); }
|	items
;

set:
	%empty							{ $$ = exp1(aloc("{}",yylloc)); }
|	setitems
;

setitems:
	exp									{ $$ = fn2loc(aloc("{}",yylloc), $1, yylloc); }
| setitems ',' exp			{ $$ = appendloc($1, $3, yylloc); }
;

items:
	exp									{ $$ = fn2loc(aloc("[]",yylloc), $1, yylloc); }
| items ',' exp				{ $$ = appendloc($1, $3, yylloc); }
;

tupel:
	'(' exp ',' exp ')'		{ $$ = fn3loc(aloc(",",yylloc), $2, $4, yylloc); }
	'(' exp ',' exp ',' exp ')'		{ $$ = fn4loc(aloc(",",yylloc), $2, $4, $6, yylloc); }
	/*'(' exp ',' exp ',' exp ',' exp ')'		{ $$ = fn5loc(aloc(",",yylloc), $2, $4, $6, $8, yylloc); }
	'(' exp ',' exp ',' exp ',' exp ',' exp ')'		{ $$ = fn3loc(aloc(",",yylloc), $1, $2, yylloc); }
	'(' exp ',' exp ',' exp ',' exp ',' exp ',' exp ')'		{ $$ = fn3loc(aloc(",",yylloc), $1, $2, yylloc); }*/

params:
	'(' exp ',' exp  ')'				{ $$ = fn3loc(aloc(",",yylloc), $2, $4, yylloc); }
|	exp ',' exp 			 					{ $$ = fn3loc(aloc(",",yylloc), $1, $3, yylloc); }
|	single											{ $$ = metloc($1, yylloc); }
/*|	params ',' NAAM			{ $$ = appendloc($1, $3, yylloc); } */
;
