#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "node.h"
#include "taal.h"
#include "global.h"

extern void rapporteer(int t, char* str);
extern void yyreset();

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

void lua_pushfout(lua_State* L, fout fout) {
	lua_createtable(L, 0, 2);
	lua_pushinteger(L, fout.lijn + 1);
	lua_setfield(L, -2, "lijn");
	lua_pushstring(L, fout.bericht);
	lua_setfield(L, -2, "bericht");
}

int lua_ontleed0(lua_State* L) {
	// reset
	yyreset();
	const char* str = luaL_checkstring(L, 1);
	in = str;
	yyparse();
	if (wortel)
		lua_pushexp(L, wortel);
	else
		lua_pushliteral(L, "fout");
	return 1;
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

	if (wortel) {
		lua_pushlisp(L, wortel);
	}
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
	lua_pushcfunction(L, lua_ontleed0);
	lua_setglobal(L, "ontleed0");
	return 1;
}

