#include <lua.h>
#include <lauxlib.h>

int main() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);
	char* str = "require 'ontleed'; require 'util'  ; a = ontleed(file('b.code')) ";
	luaL_dostring(L, str);
	return 0;
}

