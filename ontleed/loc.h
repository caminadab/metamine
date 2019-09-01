#pragma once
#define YYLTYPE_IS_DECLARED
typedef struct YYLTYPE  
{  
       int first_line;  
       int first_column;  
       int last_line;  
       int last_column;  
       char* file;
} YYLTYPE;

