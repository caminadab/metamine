/*
is-teken-witruimte = x → (x = ' ' ∨ x = 10 ∨ x = 13 ∨ x = 9
%option reentrant
%option bison-bridge
%option bison-locations
%option noyywrap nodefault
%option yylineno
*/
%option header-file="lex.yy.h"
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
	#include "node.h"

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

	typedef struct YYLTYPE YYLTYPE;
	#include "taal.yy.h"
%}


%%
"∈"					{ *yylval = a("zitin"); return NAAM; }
"∋"					{ *yylval = a("bevat"); return NAAM; }
"∉"					{ *yylval = a("!:"); return NIN; }
"⁻¹"				{ *yylval = a("^-1"); return INV; }

"⁰"					{ *yylval = a("^0"); return M0; }
"¹"					{ *yylval = a("^1"); return M1; }
"²"					{ return M2; }
"³"					{ *yylval = a("^3"); return M3; }
"⁴"					{ *yylval = a("^4"); return M4; }
"ⁿ"					{ *yylval = a("^n"); return MN; }
"₀"					{ *yylval = a("_0"); return I0; }
"₁"					{ *yylval = a("_1"); return I1; }
"₂"					{ *yylval = a("_2"); return I2; }
"₃"					{ *yylval = a("_3"); return I3; }
"₄"					{ *yylval = a("_4"); return I4; }

"×"					{ *yylval = a("xx"); return CART; }
"→"					{ *yylval = a("->"); return TO; }
"↦"					{ *yylval = a("-->"); return MAPLET; }
"⇒"					{ *yylval = a("=>"); return IMPLICEERT; }
"≈"					{ *yylval = a("~="); return ISB; }
"≥"					{ *yylval = a(">="); return GDGA; }
"≤"					{ *yylval = a("<="); return KDGA; }
"≠"					{ *yylval = a("!="); return ISN; }
"∘"					{ *yylval = a("@"); return '@'; }
"∆"					{ *yylval = a("delta"); return NAAM; }
"τ"					{ *yylval = a("tau"); return NAAM; }
"∞"					{ *yylval = a("oneindig"); return NAAM; }
"∑"					{ return SOM; }
"Σ"					{ return SOM; }
"⋂"					{ *yylval = a("INTERSECTIE"); return INTERSECTIEE; }
"⋃"					{ *yylval = a("UNIE"); return UNIEE; }
"∩"					{ *yylval = a("intersectie"); return INTERSECTIE; }
"∪"					{ *yylval = a("unie"); return UNIE; }
"∅"					{ *yylval = a("leeg"); return NAAM; }
"∧"					{ *yylval = a("en"); return EN; }
"en"				{ *yylval = a("en"); return EN; }
"∨"					{ *yylval = a("of"); return OF; }
"of"				{ *yylval = a("of"); return OF; }
"⋀"					{ *yylval = a("EN"); return ENN; }
"⋁"					{ *yylval = a("OF"); return OFN; }
"√"					{ *yylval = a("wortel"); return NAAM; }
"∛"					{ *yylval = a("derdemachtswortel"); return NAAM; }
"∜"					{ *yylval = a("vierdemachtswortel"); return NAAM; }
"∐"					{ *yylval = a("co"); return NAAM; }
"∏"					{ *yylval = a("prod"); return NAAM; }
"¬"					{ *yylval = a("niet"); return NIET; }
"★"					{ *yylval = a("_"); return NAAM; }
"☆"					{ *yylval = a("__"); return NAAM; }
"ℝ"					{ *yylval = a("getal"); return NAAM; }
"ℕ"					{ *yylval = a("nat"); return NAAM; }
"ℤ"					{ *yylval = a("int"); return NAAM; }
"·"					{ *yylval = a("*"); return '*'; }

[ ]					// negeer spaties
[\t]				{ return TAB; } // negeer tabs voor nu
":="				{ return ASS; }
"||="				{ return CATASS; }
"+="				{ return PLUSASS; }
"-="				{ return MINASS; }
"·="				{ return MAALASS; }
"/="				{ return DEELASS; }
"¬="				{ return ISN; }
"="					{ return '='; }
">"					{ return '>'; }
"<"					{ return '<'; }
"+"					{ return '+'; }
"-"					{ return '-'; }
"*"					{ return '*'; }
"/"					{ return '/'; }
"^"					{ return '^'; }
"%"					{ return '%'; }
"!"					{ return '!'; }
"|"					{ return '|'; }
"&"					{ return '&'; }
"#"					{ return '#'; }
"@"					{ return '@'; }
","					{ return ','; }
":"					{ return ':'; }
"'"					{ return '\''; }

"("					{ return '('; }
")"					{ return ')'; }
"{"					{ return '{'; }
"}"					{ return '}'; }
"["					{ return '['; }
"]"					{ return ']'; }

"->"					{ return TO; }
"||"					{ return CAT; }
".."					{ return TIL; }
"."						{ return '.'; }
"xx"					{ return CART; }
"::"					{ return ICAT; }
">="					{ return GDGA; }
"=<"					{ return KDGA; }
"<="					{ return KDGA; }
"=>"					{ return IMPLICEERT; }
"!="					{ return ISN; }

"als"					{ return ALS; }
"dan"					{ return DAN; }
"anders"			{ return ANDERS; }

'\''					{ return OUD; }

'.'					{ *yylval = karakter(yytext[1]); return TEKST; }
\"([^"]|\"\")*\"					{ *yylval = tekst(a(yytext)); return TEKST; }
\n					{ return '\n'; }
;-[^$]*-;			// negeer commentaar
;[^-][^\n]*\n		{ return '\n'; }
((\d+)|(\.\d+))(e\d*)? { *yylval = a(yytext); return NAAM; }
-?[0-9]*\.[0-9]*e[0-9]*			{ *yylval = a(yytext); return NAAM; } /* getal */
-?[0-9]*e[0-9]*			{ *yylval = a(yytext); return NAAM; }
-?[0-9]*\.[0-9]*			{ *yylval = a(yytext); return NAAM; }
-?[0-9]*			{ *yylval = a(yytext); return NAAM; }
[a-zA-Z_][a-zA-Z0-9\-_]*	{ *yylval = a(yytext); return NAAM; }
0x[0-9A-Fa-f]+			{ *yylval = a(yytext); return NAAM; }

.						{ printf("fout symbool '%s' op regel %d\n", yytext, yylineno); *yylval = a("?"); return NAAM; }

%%
