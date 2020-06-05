#define _POSIX_C_SOURCE 199309L
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


#include <lua.h>
#include <lauxlib.h>

#include <sys/select.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <math.h>
#include <unistd.h>


// meta
int socket_tostring(lua_State* L) {
	int sock = *(int*) luaL_checkudata(L, 1, "socket");
	lua_pushfstring(L, "socket %d", sock);
	return 1;
}

int socket_gc(lua_State* L) {
	int sock = *(int*) luaL_checkudata(L, 1, "socket");
	close(sock);
	return 0;
}

int socket_accept(lua_State* L) {
	int server = *(int*) luaL_checkudata(L, 1, "socket");
	int client = accept(server, 0, 0);

	int* luaclient = lua_newuserdata(L, sizeof(int));
	*luaclient = client;

	luaL_newmetatable(L, "socket");
	lua_setmetatable(L, -2);

	return 1;
}

int socket_bind(lua_State* L) {
	const char* ip = luaL_checkstring(L, 1);
	int port = luaL_checkint(L, 2);

	int sock = socket(AF_INET, SOCK_STREAM, 0);

	int* luasock = lua_newuserdata(L, sizeof(int));
	*luasock = sock;

	luaL_newmetatable(L, "socket");
	lua_setmetatable(L, -2);

	return 1;
}

int socket_select(lua_State* L) {
	int nfds = 0;
	fd_set read;
	fd_set write;
	struct timeval time;

	FD_ZERO(&read);
	FD_ZERO(&write);
	struct timeval* ptime = 0;

	// read
	if (!lua_isnil(L, 1)) {
		luaL_checktype(L, 1, LUA_TTABLE);
		lua_pushvalue(L, 1);

		lua_pushnil(L);
		while (lua_next(L, -2)) {
			if (lua_isuserdata(L, -1)) {
				int sock = *(int*) lua_touserdata(L, -2);
				FD_SET(sock, &read);
				nfds ++;
			}
		}
		lua_pop(L, 1);
	}

	// write
	if (!lua_isnil(L, 2)) {
		luaL_checktype(L, 2, LUA_TTABLE);
		lua_pushvalue(L, 2);

		lua_pushnil(L);
		while (lua_next(L, -2)) {
			if (lua_isuserdata(L, -1)) {
				int sock = *(int*) lua_touserdata(L, -2);
				FD_SET(sock, &write);
				nfds ++;
			}
		}
		lua_pop(L, 1);
	}

	// time
	if (!lua_isnil(L, 3)) {
		ptime = &time;
		time.tv_sec = luaL_checknumber(L, 3);
		time.tv_usec = fmod(luaL_checknumber(L, 3), 1.0) / 1e6;
	}

	// daar is ie dan
	select(nfds, &read, &write, 0, ptime);


	// deel 2: extract

	return 0;
}

EXPORT int luaopen_socket(lua_State* L) {
	// static socket funcs
	luaL_Reg funcs[] = {
		{"bind",   socket_bind },
		{"select", socket_select },
		{ 0, 0 },
	};
	lua_newtable(L);
	luaL_register(L, NULL, funcs);
	lua_setglobal(L, "socket");

	// socket index
	luaL_Reg index[] = {
		{"accept", socket_accept},
		{0, 0},
	};

	// socket meta
	luaL_Reg meta[] = {
		{"__gc", socket_gc },
		{"__tostring", socket_tostring },
		{0, 0},
	};
	luaL_newmetatable(L, "socket");
	luaL_register(L, NULL, meta);
	
	lua_newtable(L);
	luaL_register(L, NULL, index);
	lua_setfield(L, -2, "__index");

	return 0;
}
