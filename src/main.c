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

#define writel(fd,text) write(fd,text,sizeof(text)-1)

int sas_now(lua_State* L) {
	struct timespec now;            
	clock_gettime(CLOCK_MONOTONIC_RAW, &now);
	
	lua_pushinteger(L, now.tv_sec);
	lua_pushinteger(L, now.tv_nsec);
	return 2;
}

int sas_watch(lua_State* L) {
	char* name = lua_tostring(L, 1);
	int id = inotify_init();
	return 1;
}

int sas_file(lua_State* L) {
	char* name = lua_tostring(L, 1);
	int fd = open(name, O_RDWR);
	if (fd <= 0) {
		lua_pushnil(L);
		lua_pushstring(L, "could not open");
		return 2;
	}
	lua_pushinteger(L, fd);
	return 1;
}

int sas_server(lua_State* L) {
	int port = luaL_checkinteger(L, -1);
	int server = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	struct sockaddr_in in;
	in.sin_addr.s_addr = 0;
	in.sin_port = htons(port);
	in.sin_family = AF_INET;
	int res = bind(server, &in, sizeof(in)) || listen(server, 99);
	if (res) {
		close(server);
		lua_pushnil(L);
		lua_pushliteral(L, "address already in use");
		return 2;
	}
	lua_pushinteger(L, server);
	return 1;
}

int sas_dosafe(lua_State* L, char* buf, int len) {
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
		res = lua_pcall(L,0,0,0);
		writel(1,"\x1B[37m");
		
		if (res) {
			writel(1,"\x1B[31m");
			char* err = lua_tolstring(L, -1, &len);
			write(1,err,len);
			writel(1,"\x1B[37m\n");
			lua_pop(L, 1);
		}
	}
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

int net_read(lua_State* L, int id, int index) {
	lua_getglobal(L, "accept2magic");
	lua_pushinteger(L, id);
	lua_rawgeti(L, -2, id);
	
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
	
	lua_pop(L, 3);
}

int main() {
	writel(1, "\x1B[;f\x1B[J");
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
		{"file", sas_file},
		{"now", sas_now},
		{0, 0},
	};
	luaL_newlib(L, lib);
	lua_setglobal(L, "sas");
	
	// protect
	lua_setglobal(L, "os");
	
	int r = luaL_dofile(L, "lua/init.lua");
	if (r) {
		int len;
		char* c = lua_tolstring(L,-1,&len);
		c[len] = 0;
		write(1,c,len);
	}
	
	// prompt
	writel(1,"\x1B[33m> \x1B[37m");
	
	while (1) {
		fd_set r,w,e;
		FD_ZERO(&r);
		FD_ZERO(&w);
		FD_ZERO(&e);
		
		// listen console
		FD_SET(0,&r);
		
		// add lua server accept
		lua_getglobal(L, "read2magic");
		lua_pushnil(L);
		while (lua_next(L, 1)) { // 4,5
			// accept
			int id = lua_tointeger(L, -2);
			FD_SET(id,&r);
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
			
			sas_dosafe(L, buf, len);
			
			sas_dosafel(L, "dbg()");
			
			// prompt
			writel(1,"\x1B[33m> \x1B[37m");
		}
		
		// add lua server accept
		lua_getglobal(L, "read2magic"); // 1
		lua_pushnil(L);
			int a1 = lua_gettop(L);
		while (lua_next(L, 1)) {
			// read
			int id = lua_tointeger(L, -2);
			int magic = lua_absindex(L, -1);
			
			// MAGIC is now at 3
			int a2 = lua_gettop(L);
			if (FD_ISSET(id,&r)) {
				int a3 = lua_gettop(L);
				net_read(L, id, magic);
				int a4 = lua_gettop(L);
			int a5 = lua_gettop(L);
			}
			
			lua_pop(L, 1);
			int a6 = lua_gettop(L);
		}
		lua_pop(L,1);
			int a7 = lua_gettop(L);
	}
	
	return 0;
}
