#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "node.h"
#include "taal.yy.h"
#include "lex.yy.h"

int yyerror(YYLTYPE* loc, void** root, char* waarom, void* scanner, const char* yymsg) {
	print_loc(*loc);
	printf(": %s\n", yymsg);

	// lmao zedong
	strcpy(waarom, yymsg);

	return 0;
}

void lua_pushloc(lua_State* L, YYLTYPE loc) {
	lua_createtable(L, 0, 5);
	lua_pushinteger(L, loc.first_line + 1); lua_setfield(L, -2, "y1");
	lua_pushinteger(L, loc.first_column + 1); lua_setfield(L, -2, "x1");
	lua_pushinteger(L, loc.last_line + 1); lua_setfield(L, -2, "y2");
	lua_pushinteger(L, loc.last_column + 1 - 1); lua_setfield(L, -2, "x2");
	lua_pushstring(L, loc.file); lua_setfield(L, -2, "bron");
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

void setfile(node* node, char* file) {
	node->loc.file = file;
	if (node->next) setfile(node->next, file);
	if (node->first) setfile(node->first, file);
}

int lua_ontleed(lua_State* L) {
	luaL_checkstring(L, 1);
	lua_pushvalue(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	lua_replace(L, 1);

	char* file = "?";
	if (lua_gettop(L) == 2)
		file = (char*)luaL_checkstring(L, 2);

	const char* str = luaL_checkstring(L, 1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(str, scanner);

	char waarom[0x400];
	node* wortel;

	yyparse((void**)&wortel, (void*)&waarom, scanner);
	yylex_destroy(scanner);

	// file fixen
	setfile(wortel, file);

	if (wortel)
		lua_pushlisp(L, wortel);
	else
		lua_pushnil(L); // !!??
	return 1;
}

int lua_ontleedexp(lua_State* L) {
	luaL_checkstring(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	const char* str = lua_tostring(L, -1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(str, scanner);

	node* wortel;

	char waarom[0x400];
	yyparse((void**)&wortel, (void*)&waarom, scanner);
	wortel = wortel->first->next;
	yylex_destroy(scanner);

	// file fixen
	setfile(wortel, "<EXP>");

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
	lua_pushcfunction(L, lua_ontleed); lua_setglobal(L, "ontleed");
	lua_pushcfunction(L, lua_ontleedexp); lua_setglobal(L, "ontleedexp");
	//lua_pushcfunction(L, lua_code);
	//lua_setglobal(L, "ontleed");
	return 1;
}

