#include <lua.h>
#include <lauxlib.h>

#include "node.h"
#include "taal.h"

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
	in = luaL_checkstring(L, 1);
	lijn = 0;
	foutlen = 0;
	numnodes = 0;
	wortel = 0;
	
	// doe het!
	yyparse();

	// TEMP ERROR FIX
	if (!wortel && foutlen == 0)
		rapporteer(-2, "kon er niets van maken");

	if (wortel)
		lua_pushnode(L, wortel);
	else
		lua_pushnil(L);

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

int luaopen_ontleed(lua_State* L) {
	lua_pushcfunction(L, lua_ontleed);
	lua_setglobal(L, "ontleed");
	return 1;
}

