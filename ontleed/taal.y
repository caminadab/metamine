%define parse.error verbose
%define api.pure true
%locations
%token-table
%glr-parser
%define api.value.type {struct node*}
%lex-param {void* scanner}

%parse-param {void** root}
%parse-param {char* waarom}
%parse-param {void* scanner}

%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

	#include "node.h"
	#include "lex.yy.h"

	int yyerror(YYLTYPE* loc, void** root, char* waarom, void* scanner, const char* yymsg);

	#define A(a) aloc(a,yylloc)
	#define APPEND(a,b) appendloc(a,b,yylloc)
	#define PREPEND(a,b) prependloc(a,b,yylloc)
	#define FN1(a) metloc(a,yylloc)
	#define FN2(a,b) fn2loc(a,b,yylloc)
	#define FN3(a,b,c) fn3loc(a,b,c,yylloc)
	

%}

%token '\n' RE "regeleinde"
%token NAAM "naam"
%token TEKST "tekst"
%token ALS "als"
%token DAN "dan"
%token ANDERS "anders"
%token NIN "!:"
%token SOM "som"
%token IMPLICEERT "=>"
%token TO "->"
%token MAPLET "-->"
%token ISN "!="
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
%token TAB '\t' "tab"
%token UNIE "unie"
%token INTERSECTIE "intersectie"
%token UNIEE "UNIE"
%token INTERSECTIEE "INTERSECTIE"

%token ASS ":="
%token CATASS "||="
%token PLUSASS "+="
%token MINASS "-="
%token MAALASS "*="
%token DEELASS "/="

%token EN "en"
%token OF "of"
%token ENN "EN"
%token OFN "OF"
%token NIET "niet"
%token JOKER "_"
%token EXOF "exof"
%token NOCH "noch"

/* %precedence NAAM TEKST */
%left ALS DAN ANDERS
%left "=>"
%left SOM INTERSECTIEE UNIEE
%left EN OF EXOF NOCH NIET
%left '=' "!=" "~="
%left ":=" "*=" "/=" "+=" "-=" "|=" "&=" "||="
%left '@'
%left ':' "!:"
%left "->" "-->"
%left ','
%left '<' '>' "<=" ">="
%left '&' '|'
%left "||" "::"
%left ".."
%left "xx" UNIE INTERSECTIE
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

/* ALTERNATIEF */
input:
	%empty						{ $$ = aloc("EN", yylloc); *root = $$; }
|	input exp '\n' 		{ $$ = appendloc($1, $2, @$);  } /* lees regeltje */
|	input exp '=' block '\n' 		{ $$ = appendloc($1, fn3loc(aloc("=", @3), $2, $4, @2), @$);  } /* lees regeltje */
|	input error '\n' 	{ $$ = appendloc($1, metfout(aloc("?", @2), waarom), @$); yyerrok; } /* lees regeltje */
|	input '\n' 				/* negeer witregels */
|	error  						{ $$ = metfout(aloc("?", @1), waarom); yyerrok; }
;

/*op:
	'^' | '_' | '*' | '/' | '+' | '-'
| '[' ']' | '{' '}'
| "->" | "||" | ".." | "xx" | "=>"
| '=' | "!=" | "~=" | '>' | '<' | ">=" | "<="
| '|' | '&' | '#'
| ":=" | "+=" | "-=" | "|=" | "&="
| "en" | "of" | "exof" | "noch" | "niet"
| '.' | '@' | ':' | '!:' | ">>" | "<<"
/ = FN3wwcefn3locl%i, @$
;*/

single:
	NAAM 								{ $$ = metloc($1, @1); }
|	single '.' single																	{ $$ = fn3loc(aloc(".", @2), $1, $3, @$); }
| TEKST								{ $$ = tekstmetloc($1, @1); }
| single '%'					{ $$ = fn2loc(aloc("%", @2), $1, @$); }
| single '!'					{ $$ = fn2loc(aloc("faculteit", @2), $1, @$); }
| single '\''					{ $$ = fn2loc(aloc("'", @2), $1, @$); }
| single I0						{ $$ = fn2loc($1, aloc("0", @2), @$); }
| single I1						{ $$ = fn2loc($1, aloc("1", @2), @$); }
| single I2						{ $$ = fn2loc($1, aloc("2", @2), @$); }
| single I3						{ $$ = fn2loc($1, aloc("3", @2), @$); }
| single INV					{ $$ = fn2loc(A("inverteer"), $1, @$); }
| single M0						{ $$ = fn3loc(aloc("^", @2), $1, aloc("0", @2), @$); }
| single M1						{ $$ = fn3loc(aloc("^", @2), $1, aloc("1", @2), @$); }
| single M2						{ $$ = fn3loc(aloc("^", @2), $1, aloc("2", @2), @$); }
| single M3						{ $$ = fn3loc(aloc("^", @2), $1, aloc("3", @2), @$); }
| single M4						{ $$ = fn3loc(aloc("^", @2), $1, aloc("4", @2), @$); }
| single MN						{ $$ = fn3loc(aloc("^", @2), $1, aloc("n", @2), @$); }
|	'(' exp ')'					{ $$ = metloc($2, @$); }
| '(' exp ',' exp ')'				  %prec NAAM  { $$ = fn3loc(aloc(",", @3), $2, $4, @$); }
| '(' exp ',' exp ',' exp ')'	{ $$ = fn4loc(A(","), $2, $4, $6, @$); }
| '(' exp ',' exp ',' exp ',' exp ')'	{ $$ = fn5loc(A(","), $2, $4, $6, $8, @$); }
| '[' list ']'				{ $$ = metloc($2, @$); }
| '{' set '}'					{ $$ = metloc($2, @$); }
| '[' error 					{ $$ = metfout(A("?"), waarom); yyerrok; }
| '(' error 					{ $$ = metfout(A("?"), waarom); yyerrok; }
| '{' error 					{ $$ = metfout(A("?"), waarom); yyerrok; }

/*| '(' op ')'					{ $$ = $2; }*/

| '(' '^' ')'       	{ $$ = A("^"); }
| '(' '_' ')'       	{ $$ = A("_"); }
| '(' '*' ')'       	{ $$ = A("*"); }
| '(' '/' ')'       	{ $$ = A("/"); }
| '(' '+' ')'       	{ $$ = A("+"); }
| '(' '-' ')'       	{ $$ = A("-"); }

| '(' '[' ')'     		{ $$ = A("[]"); }

| '(' '{' ')'     		{ $$ = A("{}"); }
| '(' UNIE ')'     		{ $$ = A("unie"); }
| '(' INTERSECTIE ')' { $$ = A("intersectie"); }

| '(' "->" ')'				{ $$ = A("->"); }
| '(' "-->" ')'				{ $$ = A("-->"); }
| '(' "||" ')'				{ $$ = A("||"); }
| '(' "::" ')'				{ $$ = A("::"); }
| '(' ".." ')'				{ $$ = A(".."); }
| '(' "xx" ')'				{ $$ = A("xx"); }
| '(' "=>" ')'				{ $$ = A("=>"); }

| '(' '='	')'					{ $$ = A("="); }
| '(' "!=" ')'				{ $$ = A("!="); }
| '(' "~=" ')'				{ $$ = A("~="); }
| '(' '>' ')'					{ $$ = A(">"); }
| '(' '<' ')'					{ $$ = A("<"); }
| '(' ">=" ')'				{ $$ = A(">="); }
| '(' "<=" ')'				{ $$ = A("<="); }

| '(' "en" ')'				{ $$ = A("/\\"); }
| '(' "of" ')'				{ $$ = A("\\/"); }
| '(' "EN" ')'				{ $$ = A("EN"); }
| '(' "OF" ')'				{ $$ = A("OF"); }
| '(' '&' ')'					{ $$ = A("&"); }
| '(' '|' ')'					{ $$ = A("|"); }
| '(' '#' ')'       	{ $$ = A("#"); }

| '(' ":=" ')'				{ $$ = A(":="); }
| '(' "||=" ')'				{ $$ = A("||="); }
| '(' "*=" ')'				{ $$ = A("*="); }
| '(' "/=" ')'				{ $$ = A("/="); }
| '(' "+=" ')'				{ $$ = A("+="); }
| '(' "-=" ')'				{ $$ = A("-="); }
| '(' "|=" ')'				{ $$ = A("|="); }
| '(' "&=" ')'				{ $$ = A("&="); }

| '(' "som" ')'				{ $$ = A("som"); }
| '(' "of" ')'				{ $$ = A("of"); }
| '(' "exof" ')'			{ $$ = A("exof"); }
| '(' "noch" ')'			{ $$ = A("noch"); }
| '(' "niet" ')'			{ $$ = A("niet"); }

| '(' ',' ')'       	{ $$ = A(","); }
| '(' '.' ')'       	{ $$ = A("."); }
| '(' '@' ')'       	{ $$ = A("@"); }
| '(' ':' ')'       	{ $$ = A(":"); }
| '(' "!:" ')'       	{ $$ = A("!:"); }
| '(' ">>" ')'       	{ $$ = A(">>"); }
| '(' "<<" ')'       	{ $$ = A("<<"); }

|	'(' error ')'				{ $$ = metfout(A("?"), waarom); yyerrok; }
|	'[' error ']'				{ $$ = metfout(A("?"), waarom); yyerrok; }
|	'{' error '}'				{ $$ = metfout(FN2(A("{}"), A("?")), waarom); yyerrok; }
;

blockline: '\n' TAB exp { $$ = $3; }
block:
	blockline						{ $$ = fn2loc(A("co"), $1, @$); }
| block blockline			{ $$ = APPEND($1, $2); }
;

exp:

	single '.'																				{ $$ = fn2loc(aloc(".", @2), $1, @$); }
|	single

/* als ... dan ... */
| exp ALS exp						 														{ $$ = fn3loc(aloc("=>", @2), $3, $1, @$); }
| exp ALS '\n' TAB exp	%prec ALS										{ $$ = fn3loc(aloc("=>", @2), $5, $1, @$); }
| ALS exp DAN exp ANDERS exp  %prec ALS							{ $$ = fn4loc(aloc("=>", @1), $2, $4, $6, @$); }
/*| ALS exp DAN exp  %prec ALS												{ $$ = FN3(A("=>"), $2, $4); }*/
| ALS exp DAN '\n' TAB exp %prec ALS								{ $$ = FN3(A("=>"), $2, $6); }
| ALS '\n' TAB exp '\n' DAN '\n' TAB exp %prec ALS	{ $$ = FN3(A("=>"), $4, $9); }

/* als ... dan ... anders */
/*
als exp
	b = 2
anders
	b = 3
*/
| ALS exp DAN '\n'   		/* 1, 2, 3, 4 */
  TAB exp '\n'   				/* 5, 6, 7 */
	ANDERS '\n'   				/* 8, 9 */
	TAB exp  %prec ALS    /* 10, 11 */								{ $$ = fn4loc(aloc("=>", @1), $2, $6, $11, @$); }

| ALS exp DAN '\n' exp '\n' ANDERS '\n' exp %prec ALS { $$ = FN3(A("/\\"), FN3(A("=>"), $2, $5), FN3(A("=>"), FN2(A("!"), $2), $9)); }

| exp '^' exp       	{ $$ = fn3loc(aloc("^", @2), $1, $3, @$); }
| exp '_' exp       	{ $$ = fn3loc(aloc("_", @2), $1, $3, @$); }
| exp '*' exp       	{ $$ = fn3loc(aloc("*", @2), $1, $3, @$); }
| exp '/' exp       	{ $$ = fn3loc(aloc("/", @2), $1, $3, @$); }
| exp '+' exp       	{ $$ = fn3loc(aloc("+", @2), $1, $3, @$); }
| exp '-' exp       	{ $$ = fn3loc(aloc("-", @2), $1, $3, @$); }

| exp UNIE exp       	{ $$ = fn3loc(aloc("unie", @2), $1, $3, @$); }
| exp INTERSECTIE exp { $$ = fn3loc(aloc("intersectie", @2), $1, $3, @$); }

| SOM exp			       	{ $$ = fn2loc(aloc("som", @1), $2, @$); }
| UNIEE exp			     	{ $$ = fn2loc(aloc("UU", @1), $2, @$); }
| INTERSECTIEE exp	 	{ $$ = fn2loc(aloc("NN", @1), $2, @$); }
| exp "->" exp				{ $$ = fn3loc(aloc("->", @2), $1, $3, @$); }
| exp "-->" exp				{ $$ = fn3loc(aloc("-->", @2), $1, $3, @$); }
| exp "||" exp				{ $$ = fn3loc(aloc("||", @2), $1, $3, @$); }
| exp "::" exp				{ $$ = fn3loc(aloc("::", @2), $1, $3, @$); }
| exp ".." exp				{ $$ = fn3loc(aloc("..", @2), $1, $3, @$); }
| exp "xx" exp				{ $$ = fn3loc(aloc("xx", @2), $1, $3, @$); }
| exp "=>" exp				{ $$ = fn3loc(aloc("=>", @2), $1, $3, @$); }

| exp '='	exp					{ $$ = fn3loc(aloc("=", @2), $1, $3, @$); }
| exp "!=" exp				{ $$ = fn3loc(aloc("!=", @2), $1, $3, @$); }
| exp "~=" exp				{ $$ = fn3loc(aloc("~=", @2), $1, $3, @$); }
| exp '>' exp					{ $$ = fn3loc(aloc(">", @2), $1, $3, @$); }
| exp '<' exp					{ $$ = fn3loc(aloc("<", @2), $1, $3, @$); }
| exp ">=" exp				{ $$ = fn3loc(aloc(">=", @2), $1, $3, @$); }
| exp "<=" exp				{ $$ = fn3loc(aloc("<=", @2), $1, $3, @$); }

| '#' exp							{ $$ = fn2loc(aloc("#", @1), $2, @$); }
/*| exp '|' exp				{ $$ = fn3loc(aloc("|", @2), $1, $3, @$); }*/
| '|' exp '|'					{ $$ = fn2loc(aloc("#", @1), $2, @$); }
| exp '&' exp				{ $$ = fn3loc(aloc("&", @2), $1, $3, @$); }

| exp ":=" exp				{ $$ = fn3loc(aloc(":=", @2), $1, $3, @$); }
| exp "||=" exp				{ $$ = fn3loc(aloc("||=", @2), $1, $3, @$); }
| exp "*=" exp				{ $$ = fn3loc(aloc("*=", @2), $1, $3, @$); }
| exp "/=" exp				{ $$ = fn3loc(aloc("/=", @2), $1, $3, @$); }
| exp "+=" exp				{ $$ = fn3loc(aloc("+=", @2), $1, $3, @$); }
| exp "-=" exp				{ $$ = fn3loc(aloc("-=", @2), $1, $3, @$); }
| exp "|=" exp				{ $$ = fn3loc(aloc("|=", @2), $1, $3, @$); }
| exp "&=" exp				{ $$ = fn3loc(aloc("&=", @2), $1, $3, @$); }

| exp "en" exp				{ $$ = fn3loc(aloc("/\\", @2), $1, $3, @$); }
| exp "of" exp				{ $$ = fn3loc(aloc("\\/", @2), $1, $3, @$); }
| exp "xof" exp			{ $$ = fn3loc(aloc("xof", @2), $1, $3, @$); }
| exp "noch" exp			{ $$ = fn3loc(aloc("noch", @2), $1, $3, @$); }
| "niet" exp					{ $$ = fn2loc(aloc("!", @2), $2, @$); }

/*| exp '.' exp       	{ $$ = fn3loc(aloc(".", @2), $1, $3, @$); }*/
| exp '@' exp       	{ $$ = fn3loc(aloc("@", @2), $1, $3, @$); }
| exp ':' exp       	{ $$ = fn3loc(aloc(":", @2), $1, $3, @$); }
| exp "!:" exp       	{ $$ = fn2loc(aloc("!", @2), FN3(aloc(":", @2), $1, $3), @$); } // !(:(a b))

| '-' exp  %prec NEG	{ $$ = fn2loc(aloc("-", @2), $2, @$); }

| single single %prec CALL { $$ = fn2loc($1, $2, @$); }
| single single single %prec CALL { $$ = fn3loc($2, $1, $3, @$); }
| single single single single %prec CALL { $$ = aloc("fout", @4); yyerrok; }
|	'[' error ']'				
;

list:
	%empty							{ $$ = exp1(A("[]")); }
|	items
;

set:
	%empty							{ $$ = exp1(A("{}")); }
|	setitems
;

setitems:
	exp									{ $$ = fn2loc(A("{}"), $1, @$); }
| setitems ',' exp		{ $$ = APPEND($1, $3); }
;

items:
	exp									{ $$ = FN2(A("[]"), $1); }
| '\n' TAB exp '\n'		{ $$ = FN2(A("[]"), $3); }
| items ',' exp				{ $$ = APPEND($1, $3); }
| items TAB exp	'\n'				{ $$ = APPEND($1, $3); }
;
