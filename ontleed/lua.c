#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "node.h"
#include "taal.yy.h"
#include "lex.yy.h"
#include "global.h"

extern void rapporteer(int t, char* str);
extern void yyreset();

int yyerror(YYLTYPE* loc, void** root, void* scanner, const char* yymsg) {
	printf("%d:%d-%d:%d: %s\n", loc->first_line + 1, loc->first_column + 1, loc->first_line + 1, loc->first_column + 1, yymsg);
}

void lua_pushlisp(lua_State* L, node* node) {
	if (node->exp) {
		lua_newtable(L);
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			lua_pushinteger(L, i + 1);
			lua_pushlisp(L, n);
			lua_settable(L, -3);
			i++;
		}
	} else {
		lua_pushstring(L, node->data);
	}
}

void lua_pushexp(lua_State* L, node* node) {
	if (node->exp) {
		lua_newtable(L);
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			if (i == 0)
				lua_pushliteral(L, "fn");
			else
				lua_pushinteger(L, i);
			lua_pushexp(L, n);
			lua_settable(L, -3);
			i++;
		}
	} else {
		lua_pushstring(L, node->data);
	}
}

/*
void lua_pushfout(lua_State* L, fout fout) {
	lua_createtable(L, 0, 2);
	lua_pushinteger(L, fout.lijn + 1);
	lua_setfield(L, -2, "lijn");
	lua_pushstring(L, fout.bericht);
	lua_setfield(L, -2, "bericht");
}
*/
node* ontleed(char* code) {
	//node* wortel = yyparse(code);
	//return wortel;
	return 0;
}


int lua_ontleed(lua_State* L) {
	const char* str = luaL_checkstring(L, 1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(str, scanner);
	node* wortel;

	int ok = yyparse(&wortel, scanner);
	yylex_destroy(scanner);

	if (wortel)
		lua_pushexp(L, wortel);
	else
		lua_pushliteral(L, "fout");
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
	lua_pushcfunction(L, lua_ontleed);
	lua_setglobal(L, "ontleed");
	return 1;
}

