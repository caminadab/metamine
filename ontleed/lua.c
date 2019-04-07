#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "node.h"
#include "taal.yy.h"
#include "lex.yy.h"

int yyerror(YYLTYPE* loc, void** root, char* waarom, void* scanner, const char* yymsg) {
	print_loc(*loc);
	printf(": %s\n", yymsg);
	node* node = (struct node* )*root;

	// lmao zedong
	strcpy(waarom, yymsg);

	return 0;
}

void lua_pushloc(lua_State* L, YYLTYPE loc) {
	lua_createtable(L, 0, 4);
	lua_pushinteger(L, loc.first_line + 1); lua_setfield(L, -2, "y1");
	lua_pushinteger(L, loc.first_column + 1); lua_setfield(L, -2, "x1");
	lua_pushinteger(L, loc.last_line + 1); lua_setfield(L, -2, "y2");
	lua_pushinteger(L, loc.last_column + 1); lua_setfield(L, -2, "x2");
}

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

int lua_code(lua_State* L) {
	return 1;
}

int lua_ontleed(lua_State* L) {
	luaL_checkstring(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	const char* str = lua_tostring(L, -1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(str, scanner);

	node* wortel;

	char waarom[0x400];
	int ok = yyparse((void**)&wortel, &waarom, scanner);
	yylex_destroy(scanner);

	if (wortel)
		lua_pushlisp(L, wortel);
	else
		lua_pushnil(L); // !!??
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
	//lua_pushcfunction(L, lua_code);
	//lua_setglobal(L, "ontleed");
	return 1;
}

