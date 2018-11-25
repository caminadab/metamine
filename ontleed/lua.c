#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "node.h"
#include "taal.h"
#include "global.h"

extern void rapporteer(int t, char* str);
extern void yyreset();

void lua_pushnode(lua_State* L, node* node) {
	if (node->exp) {
		lua_newtable(L);
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			lua_pushinteger(L, i+1);
			lua_pushnode(L, n);
			lua_settable(L, -3);
			i++;
		}
	} else {
		lua_pushstring(L, node->data);
	}
}

void lua_pushfout(lua_State* L, fout fout) {
	lua_createtable(L, 0, 2);
	lua_pushinteger(L, fout.lijn + 1);
	lua_setfield(L, -2, "lijn");
	lua_pushstring(L, fout.bericht);
	lua_setfield(L, -2, "bericht");
}

// niet threadsafe lol
int lua_ontleed(lua_State* L) {
	// reset
	yyreset();
	const char* str = luaL_checkstring(L, 1);
	strcpy(buf, str);
	in = buf;

	// doe het!
	yyparse();

	// TEMP ERROR FIX
	if (!wortel && foutlen == 0)
		rapporteer(-2, "kon er niets van maken");

	if (wortel)
		lua_pushnode(L, wortel);
	else {
		lua_createtable(L, 0, 1);
		lua_pushliteral(L, "fout");
		lua_pushinteger(L, 1);
		lua_settable(L, -3);
		//lua_pushnil(L);
	}

	// fouten
	if (!foutlen)
		return 1;
	else {
		lua_createtable(L, foutlen, 0);
		for (int i = 0; i < foutlen; i++) {
			lua_pushinteger(L, i+1);
			lua_pushfout(L, fouten[i]);
			lua_settable(L, -3);
		}
		return 2;
	}
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

