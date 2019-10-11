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
	#define APPEND xlua_append
	#define FN1 xlua_reffn1
	#define FN2 xlua_reffn2
	#define FN3 xlua_reffn3
	#define FN4 xlua_reffn4
	#define FN5 xlua_reffn5

	extern lua_State* GL;
	extern YYLTYPE nergens;
%}


%%

;-[^$]*-;				// negeer commentaar
;[^-][^\n]*\n		{ return NEWLINE; }

"★"		{ *yylval = A(GL, "★", nergens); return JOKER; }
"¬"		{ *yylval = A(GL, "¬", nergens); return NIET; }
"#"		{ *yylval = A(GL, "#", nergens); return '#'; }
"→"		{ *yylval = A(GL, "→", nergens); return TO; }
".."	{ *yylval = A(GL, "..", nergens); return ITOT; }
"ℝ"		{ *yylval = A(GL, "getal", nergens); return NAAM; }
"∩"		{ *yylval = A(GL, "∩", nergens); return INTERSECTIE; }
"∪"		{ *yylval = A(GL, "∪", nergens); return UNIE; }
"⋂"		{ *yylval = A(GL, "⋂", nergens); return UNIEE; }
"⋃"		{ *yylval = A(GL, "⋃", nergens); return INTERSECTIEE; }
"‖"		{ *yylval = A(GL, "‖", nergens); return CAT; }
"||"		{ *yylval = A(GL, "‖", nergens); return CAT; }
"×"		{ *yylval = A(GL, "×", nergens); return CART; }
","		{ *yylval = A(GL, ",", nergens); return ','; }
"^"		{ *yylval = A(GL, "^", nergens); return '^'; }
"²"		{ *yylval = A(GL, "²", nergens); return KWADRAAT; }
"³"		{ *yylval = A(GL, "²", nergens); return DERDEMACHT; }
"⁻¹"	{ *yylval = A(GL, "⁻¹", nergens); return INVERTEER; }
"₀"		{ return I0; }
"₁"		{ return I1; }
"₂"		{ return I2; }
"₃"		{ return I3; }
"₄"		{ return I4; }
_			{ *yylval = A(GL, "_", nergens); return '_'; }
"("		{ *yylval = A(GL, "(", nergens); return '('; }
")"		{ *yylval = A(GL, ")", nergens); return ')'; }
"["		{ *yylval = A(GL, "[", nergens); return '['; }
"]"		{ *yylval = A(GL, "]", nergens); return ']'; }
"{"		{ *yylval = A(GL, "{", nergens); return '{'; }
"}"		{ *yylval = A(GL, "}", nergens); return '}'; }
"⋀"		{ *yylval = A(GL, "⋀", nergens); return ENN; }
"∧"		{ *yylval = A(GL, "∧", nergens); return EN; }
"en"	{ *yylval = A(GL, "∧", nergens); return EN; }
"and"	{ *yylval = A(GL, "∧", nergens); return EN; }
"∨"		{ *yylval = A(GL, "∨", nergens); return OF; }
"of"	{ *yylval = A(GL, "∨", nergens); return OF; }
"or"	{ *yylval = A(GL, "∨", nergens); return OF; }
"⋁"		{ *yylval = A(GL, "⋁", nergens); return OFF; }
"%"		{ *yylval = A(GL, "%", nergens); return '%'; }
"+"		{ *yylval = A(GL, "+", nergens); return '+'; }
"-"		{ *yylval = A(GL, "-", nergens); return '-'; }
"·"		{ *yylval = A(GL, "·", nergens); return KEER; }
"/"		{ *yylval = A(GL, "/", nergens); return '/'; }
"∘"		{ *yylval = A(GL, "∘", nergens); return COMP; }
":"		{ *yylval = A(GL, ":", nergens); return ':'; }
"∈"		{ *yylval = A(GL, ":", nergens); return ':'; }
">"		{ *yylval = A(GL, ">", nergens); return '>'; }
"≥"		{ *yylval = A(GL, "≥", nergens); return GDGA; }
"="		{ *yylval = A(GL, "=", nergens); return '='; }
"≈"		{ *yylval = A(GL, "≈", nergens); return ISB; }
"≠"		{ *yylval = A(GL, "≠", nergens); return ISN; }
"≤"		{ *yylval = A(GL, "≤", nergens); return KDGA; }
"<"		{ *yylval = A(GL, "<", nergens); return '<'; }
"!"		{ *yylval = A(GL, "!", nergens); return '!'; }
"Σ"		{ *yylval = A(GL, "Σ", nergens); return SOM; }
"⇒"		{ *yylval = A(GL, "⇒", nergens); return IMPLICEERT; }
"√"		{ *yylval = A(GL, "√", nergens); return WORTEL; }
":="		{ *yylval = A(GL, ":=", nergens); return ASS; }

"'"		{ *yylval = A(GL, "'", nergens); return '\''; }


\n		{ return NEWLINE; }
\t		// negeer tabs
" "		// negeer spaties

"ja"		{ *yylval = A(GL, "⊤", nergens); return NAAM; }
"nee"		{ *yylval = A(GL, "⊥", nergens); return NAAM; }
"⊤"			{ *yylval = A(GL, "⊤", nergens); return NAAM; }
"⊥"			{ *yylval = A(GL, "⊥", nergens); return NAAM; }
"τ"			{ *yylval = A(GL, "τ", nergens); return NAAM; }

"als"					{ return ALS; }
"dan"					{ return DAN; }
"andersals"			{ return ANDERSALS; }
"anders"			{ return ANDERS; }
"eind"			{ return EIND; }

"if"					{ return ALS; }
"then"					{ return DAN; }
"elseif"			{ return ANDERSALS; }
"else"			{ return ANDERS; }
"end"			{ return EIND; }

'.'		{ /* enkel karakter */
	char buf[10];
	sprintf(buf, "%u", yytext[1]);
	*yylval = A(GL, buf, nergens);
	return NAAM;
}

[0-9]*			{ *yylval = A(GL, yytext, nergens); return NAAM; }
[0-9]*\.[0-9]*e[0-9]*			{ *yylval = A(GL, yytext, nergens); return NAAM; }
[0-9]*e[0-9]*			{ *yylval = A(GL, yytext, nergens); return NAAM; }
[0-9]*\.[0-9]+	{ *yylval = A(GL, yytext, nergens); return NAAM; }

[a-zA-Z_][a-zA-Z0-9_\.@]* { /* naam */
	*yylval = A(GL, yytext, nergens);
	return NAAM;
}

\"([^"])*\" {
	*yylval = xlua_reftekst(GL, yytext, *yylloc); // tekst(a(yytext));
	return NAAM;
}

.			{ *yylval = A(GL, yytext, nergens); return NAAM; }

%%
