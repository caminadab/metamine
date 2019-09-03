/*
is-teken-witruimte = x → (x = ' ' ∨ x = 10 ∨ x = 13 ∨ x = 9
%option reentrant
%option bison-bridge
%option bison-locations
%option noyywrap nodefault
%option yylineno
*/
%option header-file=".lex.yy.h"
%option bison-bridge
%option bison-locations
%option ecs
%option nodefault
%option noyywrap
%option reentrant
%option stack
%option warn
%option yylineno
%option never-interactive

%{

	#define YY_USER_ACTION2 {yylloc->first_line = yylineno; \
        yylloc->first_column = yycolumn;                 \
        yycolumn=yycolumn+yyleng;                         \
        yylloc->last_column = yycolumn;                    \
        yylloc->last_line = yylineno;}

	#define YY_USER_ACTION \
    yylloc->first_line = yylloc->last_line; \
    yylloc->first_column = yylloc->last_column; \
    for(int i = 0; yytext[i] != '\0'; i++) { \
        if(yytext[i] == '\n') { \
            yylloc->last_line++; \
            yylloc->last_column = 0; \
        } \
        else { \
            yylloc->last_column++; \
        } \
    }

	#include "loc.h"
	#include ".taal.yy.h"
	#include <lua.h>
	#include "lua.h"

	#define LREG LUA_REGISTRYINDEX
	#define A xlua_refatoom
	#define FN1 xlua_reffn1

	extern lua_State* GL;
%}


%%

;-[^$]*-;				// negeer commentaar
;[^-][^\n]*\n		{ return NEWLINE; }

"★"		{ *yylval = A(GL, "★"); return JOKER; }
"¬"		{ *yylval = A(GL, "¬"); return NIET; }
"#"		{ *yylval = A(GL, "#"); return '#'; }
"."		{ *yylval = A(GL, "."); return '.'; }
"→"		{ *yylval = A(GL, "→"); return TO; }
".."	{ *yylval = A(GL, ".."); return ITOT; }
"ℝ"		{ *yylval = A(GL, "ℝ"); return RR; }
"∩"		{ *yylval = A(GL, "∩"); return INTERSECTIE; }
"∪"		{ *yylval = A(GL, "∪"); return UNIE; }
"‖"		{ *yylval = A(GL, "‖"); return CAT; }
"'"		{ *yylval = A(GL, "'"); return '\''; }
","		{ *yylval = A(GL, ","); return ','; }
"^"		{ *yylval = A(GL, "^"); return '^'; }
"²"		{ *yylval = A(GL, "²"); return KWADRAAT; }
"³"		{ *yylval = A(GL, "²"); return DERDEMACHT; }
"⁻¹"		{ *yylval = A(GL, "⁻¹"); return INVERTEER; }
_		{ *yylval = A(GL, "_"); return '_'; }
"("		{ *yylval = A(GL, "("); return '('; }
")"		{ *yylval = A(GL, ")"); return ')'; }
"["		{ *yylval = A(GL, "["); return '['; }
"]"		{ *yylval = A(GL, "]"); return ']'; }
"{"		{ *yylval = A(GL, "{"); return '{'; }
"}"		{ *yylval = A(GL, "}"); return '}'; }
"⋀"		{ *yylval = A(GL, "⋀"); return ENN; }
"∧"		{ *yylval = A(GL, "∧"); return EN; }
"en"	{ *yylval = A(GL, "∧"); return EN; }
"and"	{ *yylval = A(GL, "∧"); return EN; }
"∨"		{ *yylval = A(GL, "∨"); return OF; }
"of"	{ *yylval = A(GL, "∨"); return OF; }
"or"	{ *yylval = A(GL, "∨"); return OF; }
"⋁"		{ *yylval = A(GL, "⋁"); return OFF; }
"%"		{ *yylval = A(GL, "%"); return '%'; }
"+"		{ *yylval = A(GL, "+"); return '+'; }
"-"		{ *yylval = A(GL, "-"); return '-'; }
"·"		{ *yylval = A(GL, "·"); return KEER; }
"/"		{ *yylval = A(GL, "/"); return '/'; }
"∘"		{ *yylval = A(GL, "∘"); return COMP; }
":"		{ *yylval = A(GL, ":"); return ':'; }
">"		{ *yylval = A(GL, ">"); return '>'; }
"≥"		{ *yylval = A(GL, "≥"); return GDGA; }
"="		{ *yylval = A(GL, "="); return '='; }
"≈"		{ *yylval = A(GL, "≈"); return ISB; }
"≠"		{ *yylval = A(GL, "≠"); return ISN; }
"≤"		{ *yylval = A(GL, "≤"); return KDGA; }
"<"		{ *yylval = A(GL, "<"); return '<'; }
"!"		{ *yylval = A(GL, "!"); return '!'; }
"Σ"		{ *yylval = A(GL, "Σ"); return SOM; }
"⇒"		{ *yylval = A(GL, "⇒"); return IMPLICEERT; }

":="		{ *yylval = A(GL, ":="); return ASS; }

\n		{ return NEWLINE; }
\t		// negeer tabs
" "		// negeer spaties

"als"					{ return ALS; }
"if"					{ return ALS; }
"dan"					{ return DAN; }
"then"					{ return DAN; }
"andersals"			{ return ANDERSALS; }
"elseif"			{ return ANDERSALS; }
"anders"			{ return ANDERS; }
"else"			{ return ANDERS; }
"eind"			{ return EIND; }
"end"			{ return EIND; }

'.'		{ 
	char buf[10];
	sprintf(buf, "%u", yytext[1]);
	*yylval = A(GL, buf);
	return FOUT;
}
-?[0-9]*			{ *yylval = A(GL, yytext); return NAAM; }
-?[0-9]*\.[0-9]*e[0-9]*			{ *yylval = A(GL, yytext); return NAAM; }
-?[0-9]*e[0-9]*			{ *yylval = A(GL, yytext); return NAAM; }
-?[0-9]*\.[0-9]+	{ *yylval = A(GL, yytext); return NAAM; }

((\d+)|(\.\d+))(e\d*)? { /* getal */
	lua_pushstring(GL, yytext);
	luaL_ref(GL, LREG);
	return NAAM;
}

[a-zA-Z_][a-zA-Z0-9_]* { /* naam */
	*yylval = A(GL, yytext);
	return NAAM;
}

\"([^"])*\" {
	*yylval = xlua_reftekst(GL, yytext); // tekst(a(yytext));
	return NAAM;
}

.			{ *yylval = A(GL, yytext); return NAAM; }

%%
