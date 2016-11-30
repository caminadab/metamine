#include <lua5.2/lua.h>
#include <lua5.2/lauxlib.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

#define writel(fd,text) write(fd,text,sizeof(text)-1)

void dbg(lua_State* L) {
	// print important values
	writel(1,"\x1B[s"); // store
	luaL_dostring(L, "dbg()");
	lua_settop(L,0);
	fflush(stdout);
	
	writel(1,"\x1B[u"); // go back
}

int sas_now(lua_State* L) {
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC_RAW, &now);
	
	lua_pushinteger(L, now.tv_sec);
	lua_pushinteger(L, now.tv_nsec);
	return 2;
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

int main() {
	writel(1, "\x1B[;f\x1B[J");
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);
	
	// own library
	luaL_Reg lib[] = {
		{"server", sas_server},
		{"file", sas_file},
		{"now", sas_now},
		{0, 0},
	};
	luaL_newlib(L, lib);
	lua_setglobal(L, "sas");
	
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
		
		// listen console
		FD_SET(0,&r);
		
		// add lua server accept
		lua_getglobal(L, "sas");
		lua_getfield(L, -1, "files"); // 2
		lua_pushnil(L); // 3
		while (lua_next(L, 2)) { // 4,5
			// accept
			int sock = lua_tointeger(L, -2); // key
			FD_SET(sock,&r);
			
			// recv
			luaL_getsubtable(L,-1,"clients"); // 5, server(10101).cli
			luaL_getsubtable(L,-1,"val"); // 6
			
				lua_pushnil(L);
				while (lua_next(L, -2)) {
					int subsock = lua_tointeger(L, -2); // key
					FD_SET(subsock, &r);
					lua_pop(L, 1);
				}
			
			lua_pop(L,2);
			// end recv
			
			lua_pop(L, 1); // 3
			
		}
		lua_pop(L,2);
		
		struct timeval t;
		t.tv_sec = 0;
		t.tv_usec = 16667;
		int r2 = lua_gettop(L);
		dbg(L);
		int num = select(10,&r,&w,&e,&t);
		
		if (num == 0)
			continue;
		
		// console input
		if (FD_ISSET(0,&r)) {
			char buf[0x1000];
			int len = read(0,buf,0x1000);
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
			// prompt
			writel(1,"\x1B[33m> \x1B[37m");
		}
		
		// read lua server accept
		lua_getglobal(L, "sas");
		lua_getfield(L, -1, "files"); // 2
		lua_pushnil(L);
		while (lua_next(L, 2) != 0) {
			int sock = lua_tointeger(L, -2); // key
			if (FD_ISSET(sock, &r)) {
				int client = accept(sock,0,0);				

				// add!
				luaL_getsubtable(L,-1,"clients"); // 4, server(10101).cli
				luaL_getsubtable(L,-1,"val");
				lua_pushinteger(L, client); // key
				lua_pushliteral(L, ""); // val
				lua_settable(L, -3);
				lua_pop(L, 1);
				
				// DISCONNECT! //
				// append event
				luaL_getsubtable(L, -1, "hist"); // 
				lua_pushinteger(L, client);
				lua_pushliteral(L, "+");
				lua_concat(L, 2);
				lua_rawseti(L, -2, luaL_len(L, -2) + 1);
				lua_pop(L, 1);
				
				// send
				lua_getfield(L,-1,"out");
				if (lua_isstring(L,-1)) {
					int len;
					char* buf = lua_tolstring(L, -1, &len);
					write(client, buf, len);
				}
				lua_pop(L, 2);
			}
			
			// recv
			luaL_getsubtable(L,-1,"clients"); // 5, server(10101).cli
			luaL_getsubtable(L,-1,"val"); // 6
			
				lua_pushnil(L);
				while (lua_next(L, -2)) { // 7 key, 8 val
					int subsock = lua_tointeger(L, -2); // key
					if (FD_ISSET(subsock, &r)) {
						char buf[0x1000];
						int len = read(subsock, buf, 0x1000);
						if (!len) {
							// DISCONNECT! //
							// append event
							luaL_getsubtable(L, 5, "hist"); // 8?
							lua_pushinteger(L, subsock);
							lua_pushliteral(L, "-");
							lua_concat(L, 2);
							lua_rawseti(L, 9, luaL_len(L, 9) + 1);
							lua_pop(L, 1);
							
							// pop true, push nil
							lua_pop(L,1);
							lua_pushnil(L);
							lua_settable(L, -3);
							
						} else {
							// append!
							lua_pushlstring(L, buf, len);
							lua_concat(L, 2);
							lua_settable(L, -3);
						}
						FD_CLR(subsock, &r); // prevent reading agains
						lua_pushnil(L); // fresh key (iterate again)
						lua_pushnil(L); // fake value
					}
					lua_pop(L, 1);
				}
			
			lua_pop(L,2);
			// end recv
			
			lua_pop(L, 1);
		}
		lua_pop(L,2);
	}
	
	return 0;
}
