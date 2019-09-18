%define parse.error verbose
%define api.pure true
%locations
%token-table
%glr-parser

%define api.value.type {int}

%lex-param {void* scanner}
%parse-param {void* L}
%parse-param {int* ref}
%parse-param {int* fouten}
%parse-param {void* scanner}

%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

	#include <lua.h>

	#include "loc.h"
	#include "lua.h"

	#define LREG LUA_REGISTRYINDEX
	typedef struct lua_State lua_State;

	int yyerror(YYLTYPE* loc, lua_State* L, int* ref, int* fouten, void* scanner, const char* yymsg);
	int yylex(void* val, YYLTYPE* loc, void* scanner);

	YYLTYPE nergens = {-1, -1, -1, -1};

	#define A xlua_refatoom
	#define O xlua_refobj
	#define APPEND xlua_append
	#define APPENDA xlua_appenda
	#define LIJST xlua_reflijst
	#define LOC xlua_metloc
	#define OBJ1 xlua_refobj1
	#define FN1 xlua_reffn1
	#define FN2 xlua_reffn2
	#define FN3 xlua_reffn3
	#define FN4 xlua_reffn4
	#define FN5 xlua_reffn5
	#define TN2 xlua_reftup2
%}

%token '\n' NEWLINE "end of line"
%token FOUT
%token NAAM "name"
%token TEKST "text"
%token ALS "if"
%token DAN "then"
%token ANDERS "else"
%token ANDERSALS "elseif"
%token EIND "end"
%token NIN "!:"
%token SOM "Σ"
%token NIET "¬"
%token KWADRAAT "²"
%token DERDEMACHT "³"
%token INVERTEER "⁻¹"
%token IMPLICEERT "⇒"
%token TO "→"
%token MAPLET "↦"
%token ISN "≠"
%token CAT "‖"
%token ICAT "::"
%token ITOT ".."
%token CART "×"
%token END 0 "end of file"
%token NEG '-'
%token GDGA "≥"
%token ISB "≈"
%token KDGA "≤"
%token OUD '\''
%token TAB '\t' "tab"
%token UNIE "∪"
%token INTERSECTIE "∩"
%token UNIEE "⋃"
%token INTERSECTIEE "⋂"
%token RR "ℝ"

%token COMP "∘"
%token KEER "·"

%token ASS ":="
%token CATASS "||="
%token PLUSASS "+="
%token MINASS "-="
%token MAALASS "*="
%token DEELASS "/="

%token ENN "⋀"
%token EN "∧"
%token OF "∨"
%token OFF "⋁"
%token JOKER "★"

/* precedenties! */
%left ALS DAN ANDERS
%left "⇒"
%left SOM INTERSECTIEE UNIEE
%left EN OF EXOF NOCH NIET
%left '=' "≠" "≈"
%left ":=" "*=" "/=" "+=" "-=" "|=" "&=" "||="
%left "∘"
%left ':' "!:"
%left "→" "↦"
%left '<' '>' "≤" "≥"
%left ','
%left '&' '|'
%left "‖" "::"

%nonassoc CALL
%left "×" UNIE INTERSECTIE
%left ".."
%left '+' '-'
%left "·" '/'
%left NEG '#'
%right '^' '_'
%left OUD
%left '.'
%nonassoc '%' '!' '\'' INVERTEER M0 M1 KWADRAAT DERDEMACHT M4 MN I0 I1 I2 I3 I4
%left NAAM TEKST

%%

input:
	block			{ *ref = $1; }
;

block:
	stats			{ $$ = FN1(L, A(L,"⋀",@$), $1, @$); }
;

stats:
	%empty							{ $$ = O(L, A(L,"[]",@$), @$); }
| stats NEWLINE				{ $$ = $1; }
| stats stat NEWLINE	{ $$ = APPEND(L, $1, $2, @$); }
| stats error NEWLINE	{ $$ = APPEND(L, $1, A(L, "fout", @2), @$); yyerrok; }
;

stat:
	exp
| ALS exp DAN NEWLINE block EIND   { $$ = FN2(L, A(L,"⇒", @1), $2, $5, @$); }
| ALS exp DAN exp EIND             { $$ = FN2(L, A(L,"⇒", @1), $2, $4, @$); }
| ALS exp DAN exp ANDERS exp EIND  { $$ = FN3(L, A(L,"⇒", @1), $2, $4, $6, @$); }
/* 1   2   3   4     5    6  */

/*
als
	aaa
	bbb
dan
	ccc
	ddd
eind
*/
| ALS NEWLINE block DAN NEWLINE block EIND {
/* 1     2      3    4     5      6    7   */
	$$ = FN2(L, A(L,"⇒", @1), $3, $6, @$);
}

/*
als A dan
	B
andersals C dan
	D
anders
	E
eind
*/
| ALS exp DAN NEWLINE block ANDERSALS exp DAN NEWLINE block ANDERS NEWLINE block EIND {
/* 1   2   3     4      5      6       7   8     9     10    11      12     13  14 */
	$$ = FN5(L, A(L,"⇒", @1), $2, $5, $7, $10, $13, @$);
}

/*
als A dan
	B
andersals C dan
	D
eind
*/
| ALS exp DAN NEWLINE block ANDERSALS exp DAN NEWLINE block EIND {
/* 1   2   3     4      5      6       7   8     9     10    11  */
	$$ = FN4(L, A(L,"⇒", @1), $2, $5, $7, $10, @$);
}

/*
als A dan
	B
anders
	C
eind
*/
| ALS exp DAN NEWLINE block ANDERS NEWLINE block EIND {
/* 1   2   3     4      5      6      7      8    9   */
	$$ = FN3(L, A(L,"⇒", @1), $2, $5, $8, @$);
}
;

op:
	'^' | '_' | "·" | '/' | '+' | '-'
| '[' | ']' | '{' | '}'
| "→" | "‖" | ".." | "×" | "⇒"
| '=' | "≠" | "≈" | '>' | '<' | "≥" | "≤"
| '|' | '&'
| ":=" | "+=" | "-=" | "|=" | "&="
| "⋂" | "∩" | "∪" | "⋃"
| "⋀" | "∧" | "∨" | "⋁" | "exof" | "noch" | "¬"
| '.' | "∘" | ':' | "!:" | ">>" | "<<" | ','
;

unop:
	"¬" | '#' | "Σ"
;

single:
	NAAM										{ $$ = LOC(L, $1, @1); }
| "ℝ"
| "★"
| '(' exp ')'							{ $$ = xlua_sluit(L, LOC(L, $2, @$)); }
| '|' exp '|'							{ $$ = FN1(L, A(L,"#", @$), $2, @$); }
|	NAAM '.'								{ $$ = FN1(L, $2, $1, @$); }
|	NAAM '\''						{ $$ = FN1(L, $2, $1, @$); }
|	'(' op ')'					{ $$ = $2; }
|	'(' unop ')'				{ $$ = $2; }

/* lijst */
| '[' ']'							{ $$ = O(L, A(L,"[]",@$), @$); }
| '[' exp ']'					{ $$ = LIJST(L, A(L,"[]",@$), $2, @$); }
| '{' '}'							{ $$ = O(L, A(L,"{}",@$), @$); }
| '{' exp '}'					{ $$ = LIJST(L, A(L,"{}",@$), $2, @$); }


exp:
	single
| exp ',' exp  	{ if (xlua_isopen(L,$1)) $$ = APPEND(L, $1, $3, @$); else $$ = TN2(L, LOC(L,$2,@2), $1, $3, @$); }
| single single  %prec CALL  { $$ = FN2(L, A(L,"_", @$), $1, $2, @$); }
| single single single  %prec CALL  { $$ = FN2(L, A(L,"_",@2), $2, TN2(L, A(L,",",@2), $1, $3, @2), @$); }
| single single single single {  $$ = A(L, "fout", @$); yyerrok; }
|	exp KWADRAAT						{ $$ = FN2(L, A(L,"^", @2), $1, A(L,"2", @2), @$); }
|	exp DERDEMACHT						{ $$ = FN2(L, A(L,"^", @2), $1, A(L,"3",@2), @$); }
|	exp INVERTEER						{ $$ = FN2(L, A(L,"^", @2), $1, A(L,"-1", @2), @$); }
|	exp I0						{ $$ = FN2(L, A(L,"_", @2), $1, A(L,"0", @2), @$); }
|	exp I1						{ $$ = FN2(L, A(L,"_", @2), $1, A(L,"1", @2), @$); }
|	exp I2						{ $$ = FN2(L, A(L,"_", @2), $1, A(L,"2", @2), @$); }
|	exp I3						{ $$ = FN2(L, A(L,"_", @2), $1, A(L,"3", @2), @$); }
|	exp I4						{ $$ = FN2(L, A(L,"_", @2), $1, A(L,"4", @2), @$); }
|	"¬" exp  { $$ = FN1(L, $1, $2, @$); }
|	"Σ" exp  { $$ = FN1(L, $1, $2, @$); }
|	'-' exp  %prec NEG { $$ = FN1(L, LOC(L,$1,@1), $2, @$); }
|	'#' exp  { $$ = FN1(L, LOC(L,$1,@1), $2, @$); }
|	exp '!' { $$ = FN1(L, LOC(L,$2,@2), $1, @$); }
|	exp '%' { $$ = FN1(L, LOC(L,$2,@2), $1, @$); }

|	exp '<' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "≤" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "≈" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "≠" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "≥" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '>' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }

|	exp "‖" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "⋀" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "∧" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "∨" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "⋁" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "⋂" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "∩" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "∪" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "⋃" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "∘" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "→" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp ':' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp ".." exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "×" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp ":=" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '=' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '+' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '-' exp  { $$ = FN2(L, A(L,"+",@2), $1, FN1(L, A(L,"-",@1), $3, @3), @$); }
|	exp "·" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '/' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '_' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp '^' exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }
|	exp "⇒" exp  { $$ = FN2(L, LOC(L,$2,@2), $1, $3, @$); }

;

