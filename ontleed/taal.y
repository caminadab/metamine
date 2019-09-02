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
	int plus(int a, int b) { return a + b; }

	#define A xlua_refatoom
	#define FN1 xlua_reffn1
	#define FN2 xlua_reffn2
	#define FN3 xlua_reffn3
	#define FN4 xlua_reffn4
	#define FN5 xlua_reffn5
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

%token EN "∧"
%token OF "∨"
%token ENN "⋀"
%token OFF "⋁"
%token JOKER "★"

/* %precedence NAAM TEKST */
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
%left "×" UNIE INTERSECTIE
%left ".."
%left '+' '-'
%nonassoc CALL
%left "·" '/'
%left NEG '#'
%right '^' '_'
%left OUD
%left '.'
%nonassoc '%' '\'' INVERTEER M0 M1 KWADRAAT DERDEMACHT M4 MN I0  I2 I3 I4
%left NAAM TEKST

%%

input:
	block			{ *ref = $1; }
;

block:
	stats							{ $$ = $1; }
;

stats:
	%empty							{
		// { f="⋀" }
		lua_createtable(L, 0, 4);
			xlua_pushatoom(L, "⋀");
				lua_setfield(L, -2, "f");
		$$ = luaL_ref(L, LREG);
	}
| stats NEWLINE				{ $$ = $1; }
| stats stat NEWLINE	{
		lua_rawgeti(L, LREG, $1); // stats
		lua_rawgeti(L, LREG, $2); // stats, stat

		int len = lua_objlen(L, -2);
		lua_rawseti(L, -2, len+1); // stats
		$$ = luaL_ref(L, LREG); // [] :)
		luaL_unref(L, LREG, $1);
		luaL_unref(L, LREG, $2);
}
			
| stats error NEWLINE				{ $$ = xlua_append(L, $1, A(L, "fout")); yyerrok; }
;

stat:
	exp

| ALS exp DAN NEWLINE block EIND {
	lua_createtable(L, 0, 2);
		lua_rawgeti(L, LREG, $2);
			lua_rawseti(L, -2, 1);
		xlua_pushatoom(L, "⇒");
			lua_setfield(L, -2, "f");
		lua_rawgeti(L, LREG, $5);
			lua_rawseti(L, -2, 2);
	luaL_unref(L, LREG, $2);
	luaL_unref(L, LREG, $5);
	$$ = luaL_ref(L, LREG);
}

| ALS exp DAN exp EIND {
	lua_createtable(L, 0, 2);
		lua_rawgeti(L, LREG, $2);
			lua_rawseti(L, -2, 1);
		xlua_pushatoom(L, "⇒");
			lua_setfield(L, -2, "f");
		lua_rawgeti(L, LREG, $4);
			lua_rawseti(L, -2, 2);
	luaL_unref(L, LREG, $2);
	luaL_unref(L, LREG, $4);
	$$ = luaL_ref(L, LREG);
}

| ALS exp DAN exp ANDERS exp EIND {
/* 1   2   3   4     5    6  */
	$$ = FN3(L, A(L,"⇒"), $2, $4, $6);
}

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
	$$ = FN2(L, A(L,"⇒"), $3, $6);
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
	$$ = FN5(L, A(L,"⇒"), $2, $5, $7, $10, $13);
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
	$$ = FN4(L, A(L,"⇒"), $2, $5, $7, $10);
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
	$$ = FN3(L, A(L,"⇒"), $2, $5, $8);
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
	NAAM
| "ℝ"
| "★"
| '(' exp ')'							{ $$ = $2; }
| '|' exp '|'							{ $$ = FN1(L, A(L,"#"), $2); }
|	NAAM '.'								{
	$$ = FN1(L, $2, $1);
}
|	NAAM '\''								{ $$ = FN1(L, $2, $1); }
|	'(' op ')'								{ $$ = $2; }
|	'(' unop ')'								{ $$ = $2; }

/* lijst */
| '[' items ']'		{
	// op: {v="[]"}
	lua_createtable(L, 2, 1);
		lua_rawgeti(L, LREG, $1); // op
			lua_setfield(L, -2, "f");
		lua_rawgeti(L, LREG, $2); // a
			lua_rawseti(L, -2, 1);

	$$ =  luaL_ref(L, LREG);
}
;

items: exp;


exp:
	single
| single single  %prec CALL{
		// op: {v="+"}
		lua_createtable(L, 2, 1);
			// f(x) = _(f x)
			xlua_pushatoom(L, "_");
				lua_setfield(L, -2, "f");
			lua_rawgeti(L, LREG, $1); // op
				lua_rawseti(L, -2, 1);
			lua_rawgeti(L, LREG, $2); // a
				lua_rawseti(L, -2, 2);
		luaL_unref(L, LREG, $1);
		luaL_unref(L, LREG, $2);

		$$ = luaL_ref(L, LREG);
}
| single single single  %prec CALL {
		// op: {v="+"}
		lua_createtable(L, 2, 1);
			// x f y = _(f x y)
			xlua_pushatoom(L, "_");
				lua_setfield(L, -2, "f");
			lua_rawgeti(L, LREG, $2); // op
				lua_rawseti(L, -2, 1);
			lua_rawgeti(L, LREG, $1); // a
				lua_rawseti(L, -2, 2);
			lua_rawgeti(L, LREG, $3); // b
				lua_rawseti(L, -2, 3);
		luaL_unref(L, LREG, $1);
		luaL_unref(L, LREG, $2);
		luaL_unref(L, LREG, $3);

		$$ = luaL_ref(L, LREG);
}
|	exp KWADRAAT						{ $$ = FN2(L, A(L,"^"), $1, A(L,"2")); }
|	exp DERDEMACHT						{ $$ = FN2(L, A(L,"^"), $1, A(L,"3")); }
|	exp INVERTEER						{ $$ = FN2(L, A(L,"^"), $1, A(L,"-1")); }
|	"¬" exp  { $$ = FN1(L, $1, $2); }
|	"Σ" exp  { $$ = FN1(L, $1, $2); }
|	'-' exp  %prec NEG { $$ = FN1(L, $1, $2); }
|	'#' exp  { $$ = FN1(L, $1, $2); }
|	exp '!' { $$ = FN1(L, $2, $1); }
|	exp '%' { $$ = FN1(L, $2, $1); }

/*
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
|	exp op exp  { $$ = FN2(L, $2, $1, $3); }
*/

|	exp '<' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "≤" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "≈" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "≠" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "≥" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '>' exp  { $$ = FN2(L, $2, $1, $3); }

|	exp "‖" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "⋀" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "∧" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "∨" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "⋁" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "⋂" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "∩" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "∪" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "⋃" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "∘" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "→" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp ':' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp ".." exp  { $$ = FN2(L, $2, $1, $3); }
|	exp ',' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp ":=" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '=' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '-' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '+' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '/' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "·" exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '_' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp '^' exp  { $$ = FN2(L, $2, $1, $3); }
|	exp "⇒" exp  { $$ = FN2(L, $2, $1, $3); }

;

