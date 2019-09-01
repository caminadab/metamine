%define parse.error verbose
%define api.pure true
%locations
%token-table
%glr-parser

%define api.value.type {struct lua_State*}

%lex-param {void* scanner}
%parse-param {void* L}
%parse-param {void* scanner}

%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

	#include <lua.h>

	#include "loc.h"
	#define LREG LUA_REGISTRYINDEX
	typedef struct lua_State lua_State;

	int yyerror(YYLTYPE* loc, lua_State* L, void* scanner, const char* yymsg);
	int plus(int a, int b) { return a + b; }

%}

%token '\n' NEWLINE "end of line"
%token FOUT
%token NAAM "naam"
%token TEKST "tekst"
%token ALS "als"
%token DAN "dan"
%token ANDERS "anders"
%token EIND "eind"
%token NIN "!:"
%token SOM "som"
%token IMPLICEERT "⇒"
%token TO "→"
%token MAPLET "↦"
%token ISN "≠"
%token CAT "‖"
%token ICAT "::"
%token TIL ".."
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

%token ASS ":="
%token CATASS "||="
%token PLUSASS "+="
%token MINASS "-="
%token MAALASS "*="
%token DEELASS "/="

%token EN "∧"
%token OF "∨"
%token ENN "⋀"
%token OFN "⋁"
%token NIET "¬"
%token JOKER "★"
%token EXOF "exof"
%token NOCH "noch"

/* %precedence NAAM TEKST */
%left ALS DAN ANDERS
%left "⇒"
%left SOM INTERSECTIEE UNIEE
%left EN OF EXOF NOCH NIET
%left '=' "≠" "≈"
%left ":=" "*=" "/=" "+=" "-=" "|=" "&=" "||="
%left '@'
%left ':' "!:"
%left "→" "↦"
%left ','
%left '<' '>' "≤" "≥"
%left '&' '|'
%left "‖" "::"
%left "×" UNIE INTERSECTIE
%left ".."
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
	'+'							
;

block:
	stats							{ $$ = $1; }
;

stats:
	%empty							{
		// { f="⋀" }
		lua_createtable(L, 0, 0);
		lua_pushliteral(L, "⋀");
		lua_setfield(L, -2, "f");
		$$ = luaL_ref(L, LREG);
	}
| stats stat NEWLINE	{
		lua_rawgeti(L, LREG, $1); // stats
		lua_rawgeti(L, LREG, $2); // stats, stat

		int len = lua_objlen(L, -2);
		lua_rawseti(L, -2, len); // stats
		$$ = luaL_ref(L, LREG); // [] :)
		luaL_unref(L, LREG, $1);
		luaL_unref(L, LREG, $2);
};
			
| stats NEWLINE				{ $$ = $1; }
| stats error					{ $$ = $1; }
;

stat:
	exp 								{ $$ = $1; }
;

exp:
	'+'								{ puts("JA!"); }
;

