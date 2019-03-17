/* A Bison parser, made by GNU Bison 3.2.4.  */

/* Skeleton interface for Bison GLR parsers in C

   Copyright (C) 2002-2015, 2018 Free Software Foundation, Inc.

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
    DAN = 260,
    TO = 261,
    MAPLET = 262,
    ASS = 263,
    ISN = 264,
    INC = 265,
    CAT = 266,
    TIL = 267,
    CART = 268,
    NEG = 269,
    GDGA = 270,
    ISB = 271,
    KDGA = 272,
    OUD = 273,
    TAB = 274,
    EN = 275,
    OF = 276,
    NIET = 277,
    JOKER = 278,
    EXOF = 279,
    NOCH = 280,
    CALL = 284,
    INV = 285,
    M0 = 286,
    M1 = 287,
    M2 = 288,
    M3 = 289,
    M4 = 290,
    MN = 291,
    I0 = 292,
    I1 = 293,
    I2 = 294,
    I3 = 295,
    I4 = 296
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
