/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Skeleton interface for Bison GLR parsers in C

   Copyright (C) 2002-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_TAAL_YY_H_INCLUDED
# define YY_YY_TAAL_YY_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    END = 0,
    NAAM = 258,
    TEKST = 259,
    NIN = 260,
    DAN = 261,
    TO = 262,
    MAPLET = 263,
    ASS = 264,
    ISN = 265,
    INC = 266,
    CAT = 267,
    ICAT = 268,
    TIL = 269,
    CART = 270,
    NEG = 271,
    GDGA = 272,
    ISB = 273,
    KDGA = 274,
    OUD = 275,
    TAB = 276,
    EN = 277,
    OF = 278,
    NIET = 279,
    JOKER = 280,
    EXOF = 281,
    NOCH = 282,
    CALL = 286,
    INV = 287,
    M0 = 288,
    M1 = 289,
    M2 = 290,
    M3 = 291,
    M4 = 292,
    MN = 293,
    I0 = 294,
    I1 = 295,
    I2 = 296,
    I3 = 297,
    I4 = 298
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef struct node* YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif

/* Location type.  */
#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE YYLTYPE;
struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
};
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif



int yyparse (void** root, void* scanner);

#endif /* !YY_YY_TAAL_YY_H_INCLUDED  */
