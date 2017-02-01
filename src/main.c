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

#define writel(fd,text) write(fd,text,sizeof(text)-1)

int sas_server(lua_State* L);
int sas_client(lua_State* L);

int sas_now(lua_State* L);
int sas_watch(lua_State* L);
int sas_readfile(lua_State* L);
int sas_deletefile(lua_State* L);
int sas_writefile(lua_State* L);

int sas_dofile(lua_State* L, char* path) {
	lua_getglobal(L, "onerror");
	int onerror = lua_gettop(L);
	int len = 0;
	int res = luaL_loadfile(L, path);
	if (res) {
		writel(1,"\x1B[31m");
		const char* err = lua_tolstring(L, -1, &len);
		write(1,err,len);
		writel(1,"\x1B[37m\n");
		lua_pop(L, 1);
	} else {
		// blue output
		writel(1,"\x1B[36m");
		res = lua_pcall(L,0,0,onerror);
		writel(1,"\x1B[37m");
		
		if (res) {
			writel(1,"\x1B[31m");
			const char* err = lua_tolstring(L, -1, &len);
			write(1,err,len);
			writel(1,"\x1B[37m\n");
			lua_pop(L, 1);
		}
	}
	
	// pop error func
	lua_pop(L, 1);
	
	return res;
}

int sas_dosafe(lua_State* L, char* buf, int len) {
	lua_getglobal(L, "onerror");
	int onerror = lua_gettop(L);
	
	int res = luaL_loadbuffer(L,buf,len,"in");
	if (res) {
		writel(1,"\x1B[31m");
		char* err = lua_tolstring(L, -1, &len);
		write(1,err,len);
		writel(1,"\x1B[37m\n");
		lua_pop(L, 1);
	} else {
		// blue output
		writel(1,"\x1B[36m");
		res = lua_pcall(L,0,0,onerror);
		writel(1,"\x1B[37m");
		
		if (res) {
			writel(1,"\x1B[31m");
			char* err = lua_tolstring(L, -1, &len);
			write(1,err,len);
			writel(1,"\x1B[37m\n");
			lua_pop(L, 1);
		}
	}
	
	// pop error func
	lua_pop(L, 1);
	
	return res;
}

#define sas_dosafel(L,text) sas_dosafe(L,text,sizeof(text)-1)

static void stackDump (lua_State *L) {
	printf("\n");
		int i=lua_gettop(L);
		printf(" ----------------  Stack Dump ----------------\n" );
		while(  i   ) {
            int t = lua_type(L, i);
            switch (t) {
              case LUA_TSTRING:
                printf("%d:`%s'\n", i, lua_tostring(L, i));
              break;
              case LUA_TBOOLEAN:
                printf("%d: %s\n",i,lua_toboolean(L, i) ? "true" : "false");
              break;
              case LUA_TNUMBER:
                printf("%d: %g\n",  i, lua_tonumber(L, i));
             break;
             default: printf("%d: %s\n", i, lua_typename(L, t)); break;
            }
           i--;
          }
         printf("--------------- Stack Dump Finished ---------------\n" );

	fflush(stdout);
}

int io_write(lua_State* L) {
	int len;
	const char* str = luaL_checklstring(L, 1, &len);
	len = write(1, str, len);
	lua_pushinteger(L, len);
	return 1;
}

int net_write(lua_State* L, int id, int index) {
	lua_getglobal(L, "write2data");
	lua_rawgeti(L, -1, id);
	
	int len;
	char* buf = lua_tolstring(L, -1, &len);
	const int written = write(id, buf, len);
	
	// written
	if (written > 0) {
		lua_getfield(L, index, "write");
		lua_pushnil(L); lua_copy(L, index, -1); // magic val
		lua_pushinteger(L, written);
		lua_call(L, 2, 0);
	}
	
	// close !
	else {
		lua_getfield(L, index, "close");
		lua_pushnil(L); lua_copy(L, index, -1); // magic val
		lua_call(L, 1, 0);
	}
		  
	lua_pop(L, 2);
	return 0;
}

int net_read(lua_State* L, int id, int index) {
	lua_getglobal(L, "accept2magic");
	lua_rawgeti(L, -1, id);
	
	// accept
	if (lua_toboolean(L, -1)) {
		struct sockaddr_in in;
		int len = sizeof(in);
		int cid = accept(id, &in, &len);
		
		if (cid >= 0) {
			lua_getfield(L, index, "accept");
			lua_pushnil(L); lua_copy(L, index, -1); // magic val
			lua_pushinteger(L, cid);
			lua_pushlstring(L, &in, len);
			lua_call(L, 3, 0);
		}	
	}

	// recv
	else {
		char buf[0x1000];
		int len = read(id, buf, 0x1000);
	
		// data
		if (len > 0) {
			lua_getfield(L, index, "read");
			lua_pushnil(L); lua_copy(L, index, -1); // magic val
			lua_pushlstring(L, buf, len);
			lua_call(L, 2, 0);
		}
		
		// close
		else {
			lua_getfield(L, index, "close");
			lua_pushnil(L); lua_copy(L, index, -1); // magic val
			lua_call(L, 1, 0);
		}
	}
	
	// trigger
	lua_getglobal(L, "trigger");
	lua_pushnil(L); lua_copy(L, index, -1); // magic val
	lua_call(L, 1, 0);
	
	lua_pop(L, 2);
}

int main() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);
	
	// io lib
	luaL_Reg io[] = {
		{"write", io_write},
		{0,0},
	};
	luaL_newlib(L, io);
	lua_setglobal(L, "io");
	lua_pushnil(L);
	
	// own librarytrigger
	luaL_Reg lib[] = {
		{"server", sas_server},
		{"client", sas_client},
		{"writefile", sas_writefile},
		{"readfile", sas_readfile},
		{"deletefile", sas_deletefile},
		{"now", sas_now},
		{0, 0},
	};
	luaL_newlib(L, lib);
	lua_setglobal(L, "sas");
	
	// protect
	lua_setglobal(L, "os");
	
	int r = sas_dofile(L, "lua/init.lua");
	if (r) {
		int len;
		const char* c = lua_tolstring(L,-1,&len);
		write(1,c,len);
	}
	
	// prompt
	writel(1,"\x1B[33m> \x1B[37m");
	
	sas_dofile(L, "satis.lua");
	
	// watch satis.lua
	int wd = inotify_init();
	int sd = inotify_add_watch(wd, "satis.lua", IN_MODIFY);
	
	while (1) {
		fd_set r,w,e;
		FD_ZERO(&r);
		FD_ZERO(&w);
		FD_ZERO(&e);
		
		// listen console
		FD_SET(0,&r);
		FD_SET(wd,&r);
		
		// wait read
		lua_getglobal(L, "read2magic");
		lua_pushnil(L);
		while (lua_next(L, 1)) { // 4,5
			int id = lua_tointeger(L, -2);
			FD_SET(id,&r);
			lua_pop(L, 1);
		}
		lua_pop(L,1);
		
		// wait write
		lua_getglobal(L, "write2magic");
		lua_pushnil(L);
		while (lua_next(L, 1)) { // 4,5
			int id = lua_tointeger(L, -2);
			FD_SET(id,&w);
			lua_pop(L, 1);
		}
		lua_pop(L,1);
		
		struct timeval t;
		t.tv_sec = 9999999;
		t.tv_usec = 0;
		int r2 = lua_gettop(L);
		int num = select(10,&r,&w,&e,&t);
		
		if (num < 0)
			break;
		
		// console input
		if (FD_ISSET(0,&r)) {
			char buf[0x1000];
			int len = read(0,buf,0x1000);
			
			// console closed
			if (!len)
				break;
			
			sas_dosafe(L, buf, len);
			
			// prompt
			writel(1,"\x1B[G\x1B[33m> \x1B[37m");
		}
		
		if (FD_ISSET(wd,&r)) {
			struct inotify_event ev;
			read(wd, &ev, sizeof(ev));
			sas_dofile(L, "satis.lua");
			sas_dosafel(L, "dbg()");
		}
		
		// read
		lua_getglobal(L, "read2magic"); // 1
		lua_pushnil(L);
		while (lua_next(L, 1)) {
			int id = lua_tointeger(L, -2);
			int magic = lua_absindex(L, -1);
			
			// MAGIC is now at 3
			if (FD_ISSET(id,&r)) {
				net_read(L, id, magic);
			}
			
			lua_pop(L, 1);
		}
		lua_pop(L,1);
		
		// write
		lua_getglobal(L, "write2magic"); // 1
		lua_pushnil(L);
		while (lua_next(L, 1)) {
			int id = lua_tointeger(L, -2);
			int magic = lua_absindex(L, -1);
			
			// MAGIC is now at 3
			if (FD_ISSET(id,&w)) {
				net_write(L, id, magic);
			}
			
			lua_pop(L, 1);
		}
		lua_pop(L,1);
	}
	
	return 0;
}
