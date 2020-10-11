#include <lua.h>
#include <lauxlib.h>
#include <assert.h>
#include "lua.h"

void test() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	// push werkt?
	int top = lua_gettop(L);
	YYLTYPE loc;
	xlua_pushloc(L, loc);
	assert(lua_gettop(L) == top + 1);

	// atoom
	xlua_pushatoom(L, "hoi", loc);
	assert(lua_gettop(L) == top + 2);

	// ref atoom
	int atoom = xlua_refatoom(L, "hallo", loc);
	assert(lua_gettop(L) == top + 2);

	// met loc
	xlua_metloc(L, atoom, loc);
	assert(lua_gettop(L) == top + 2);
}

/*
int xlua_append(lua_State* L, int aid, int bid, YYLTYPE loc);
int xlua_metloc(lua_State* L, int aid, YYLTYPE loc);
int xlua_pushatoom(lua_State* L, char* text, YYLTYPE loc);
int xlua_reftekst(lua_State* L, char* str, YYLTYPE loc);
int xlua_refatoom(lua_State* L, char* text, YYLTYPE loc);
int xlua_reffn0(lua_State* L, int fid, YYLTYPE loc);
int xlua_reffn1(lua_State* L, int fid, int aid, YYLTYPE loc);
int xlua_reffn2(lua_State* L, int fid, int aid, int bid, YYLTYPE loc);
int xlua_reffn3(lua_State* L, int fid, int aid, int bid, int cid, YYLTYPE loc);
int xlua_reffn4(lua_State* L, int fid, int aid, int bid, int cid, int did, YYLTYPE loc);
int xlua_reffn5(lua_State* L, int fid, int aid, int bid, int cid, int did, int eid, YYLTYPE loc);
*/

int main() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);
	char* str = " require 'parse'; require 'util'  ; print('ontleden b') ; b = file('b.code') ; print(b); parse(b) ;print('hoi');  b = parse(file('../bieb/std.code')) ; print('ja!')";
	//luaL_dostring(L, str);
	if (lua_gettop(L) > 0) {
		puts(luaL_checkstring(L, 1));
	}

	test();

	return 0;
}

