#include <lua5.2/lua.h>
#include <lua5.2/lauxlib.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/inotify.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

int sas_now(lua_State* L) {
	struct timespec now;
	//clock_gettime(CLOCK_MONOTONIC_RAW, &now);
	
	lua_pushinteger(L, now.tv_sec);
	lua_pushinteger(L, now.tv_nsec);
	return 2;
}

int sas_watch(lua_State* L) {
	char* name = lua_tostring(L, 1);
	int id = inotify_init();
	return 1;
}

int sas_readfile(lua_State* L) {
	char* name = lua_tostring(L, 1);
	int fd = open(name, O_RDWR);
	
	if (fd <= 0) {
		lua_pushnil(L);
		lua_pushliteral(L, "read failed");
		return 2;
	}
	
	char buf[0x10000];
	int len = read(fd, buf, 0x10000);
	
	lua_pushlstring(L, buf, len);
	
	return 1;
}

int sas_deletefile(lua_State* L) {
	char* name = luaL_checkstring(L, 1);
	int res = unlink(name);
	lua_pushboolean(L, !res);
	return 1;
}

int sas_writefile(lua_State* L) {
	char* name = luaL_checkstring(L, 1);
	int len = 0;
	const char* buf = luaL_checklstring(L, 2, &len);
	int fd = creat(name, 0644);
	
	if (fd <= 0) {
		lua_pushnil(L);
		lua_pushstring(L, "write failed");
		return 2;
	}
	
	len = write(fd, buf, len);
	lua_pushinteger(L, len);
	close(fd);
	return 1;
}
