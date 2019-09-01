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
%}


%%

"+"		{ return '+'; }
"\t"	// negeer tabs
" "		// negeer spaties

%%
