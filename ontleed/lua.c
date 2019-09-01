#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "loc.h"
#include ".taal.yy.h"
#include ".lex.yy.h"

/*
	int yyerror(YYLTYPE* loc, void** root, struct fout* fouten, int* numfouten, int maxfouten, void* scanner, const char* yymsg) {
		if (*numfouten <= MAXFOUTEN) {
			struct fout* fout = &fouten[*numfouten];
			fout->loc = *loc; // loc
			if (*numfouten < MAXFOUTEN)
				strcpy(fout->msg, yymsg); //msg
			else
				strcpy(fout->msg, "teveel syntaxfouten");
			*numfouten += 1;
		}

	return 0;
}
*/

void lua_pushloc(lua_State* L, YYLTYPE loc) {
	lua_createtable(L, 0, 5);
	lua_pushinteger(L, loc.first_line + 1); lua_setfield(L, -2, "y1");
	lua_pushinteger(L, loc.first_column + 1); lua_setfield(L, -2, "x1");
	lua_pushinteger(L, loc.last_line + 1); lua_setfield(L, -2, "y2");
	lua_pushinteger(L, loc.last_column + 1 - 1); lua_setfield(L, -2, "x2");
	lua_pushstring(L, loc.file); lua_setfield(L, -2, "bron");
}

/*
void lua_pushlisp(lua_State* L, node* node) {
	// waarde
	lua_newtable(L);

	// locatie
	lua_pushliteral(L, "loc");
	lua_pushloc(L, node->loc);
	lua_settable(L, -3);

	// fout
	if (*node->fout) {
		lua_pushliteral(L, "fout");
		lua_pushstring(L, node->fout);
		lua_settable(L, -3);
	}

	// is tekst
	if (node->tekst) {
		lua_pushliteral(L, "tekst");
		lua_pushboolean(L, 1);
		lua_settable(L, -3);
	}

	if (node->exp) {
		// velden
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			if (i == 0)
				lua_pushliteral(L, "fn");
			else
				lua_pushinteger(L, i);
			lua_pushlisp(L, n);
			lua_settable(L, -3);
			i++;
		}
	} else {
		// data
		lua_pushliteral(L, "v");
		lua_pushstring(L, node->data);
		lua_settable(L, -3);
	}
}
*/

int lua_code(lua_State* L) {
	return 1;
}

// ontleed(code [, bron])
int lua_ontleed(lua_State* L) {
	// voeg '\n' aan het einde toe
	luaL_checkstring(L, 1);
	lua_pushvalue(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	lua_replace(L, 1);

	// bron (of "?")
	char* file = "?";
	if (lua_gettop(L) == 2)
		file = (char*)luaL_checkstring(L, 2);

	// code
	const char* code = luaL_checkstring(L, 1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	yyparse(L, scanner);
	yylex_destroy(scanner);

	// file fixen
	//setfile(wortel, file);

	// fouten pushen
	/*lua_createtable(L, numfouten, 0);
	for (int i = 0; i < numfouten; i++) {
		// index
		lua_pushinteger(L, i+1);
		// fout
		lua_createtable(L, 0, 3);
		{
			// type
			lua_pushstring(L, "syntax");
			lua_setfield(L, -2, "type");
			// fmt
			lua_pushstring(L, fouten[i].msg);
			lua_setfield(L, -2, "fmt");
			// loc
			lua_pushloc(L, fouten[i].loc);
			lua_setfield(L, -2, "loc");
		}
		lua_settable(L, -3);
	}
	*/
	return 2;
}

int yyerror(YYLTYPE* loc, lua_State* L, void* scanner, const char* yymsg) {
	puts(yymsg);
	return 0;
}

int lua_ontleedexp(lua_State* L) {
	luaL_checkstring(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	const char* str = lua_tostring(L, -1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(str, scanner);

	yyparse(L, scanner);
	yylex_destroy(scanner);

	// file fixen
	//setfile(wortel, "<EXP>");
	return 1;
}

#ifdef _WIN32 //defined(_MSC_VER)
	#define EXPORT __declspec(dllexport)
	#define IMPORT __declspec(dllimport)
#elif defined(__GNUC__)
	#define EXPORT __attribute__((visibility("default")))
	#define IMPORT
#else
	#define EXPORT
	#define IMPORT
	#pragma warning Hoe te exporteren?
#endif

EXPORT int luaopen_ontleed(lua_State* L) {
	lua_pushcfunction(L, lua_ontleed); lua_setglobal(L, "ontleed");
	lua_pushcfunction(L, lua_ontleedexp); lua_setglobal(L, "ontleedexp");
	return 1;
}

