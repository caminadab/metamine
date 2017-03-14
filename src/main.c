#include <lua5.2/lua.h>
#include <lua5.2/lauxlib.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/inotify.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#define writel(fd,text) write(fd,text,sizeof(text)-1)
#define sas_dosafel(L,text) sas_dosafe(L,text,sizeof(text)-1)

#define RED "\x1B[32m"
#define CYAN "\x1B[36m"
#define WHITE "\x1B[37m"
#define PROMPT "\x1B[33m> \x1B[37m"

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
		writel(1,RED);
		const char* err = lua_tolstring(L, -1, &len);
		write(1,err,len);
		writel(1,WHITE);
		lua_pop(L, 1);
	} else {
		res = lua_pcall(L,0,0,onerror);
		
		if (res) {
			writel(1,RED);
			const char* err = lua_tolstring(L, -1, &len);
			write(1,err,len);
			writel(1,WHITE);
			lua_pop(L, 1);
		}
	}
	
	// pop error func
	lua_pop(L, 1);
	
	return res;
}

int sas_call(lua_State* L, int nargs, int nres) {
	lua_getglobal(L, "onerror");
	int onerror = lua_gettop(L) - nargs - 1;
	lua_insert(L, onerror);

	int len;
	int res = lua_pcall(L, nargs, nres, onerror);
	
	if (res) {
		writel(1,RED);
		const char* err = lua_tolstring(L, -1, &len);
		write(1,err,len);
		writel(1,WHITE);
		lua_pop(L, 1);
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
		writel(1,RED);
		const char* err = lua_tolstring(L, -1, &len);
		write(1,err,len);
		writel(1,WHITE);
		lua_pop(L, 1);
	} else {
		// blue output
		res = lua_pcall(L,0,0,onerror);
		
		if (res) {
			writel(1,RED);
			const char* err = lua_tolstring(L, -1, &len);
			write(1,err,len);
			writel(1,WHITE);
			lua_pop(L, 1);
		}
	}
	
	// pop error func
	lua_pop(L, 1);
	
	return res;
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

// epoll id
int eid;

int io_write(lua_State* L) {
	int len;
	const char* str = luaL_checklstring(L, 1, &len);
	len = write(1, str, len);
	lua_pushinteger(L, len);
	return 1;
}

// report that a write has happened to the lua onwrite method
// also keep reading if keepreading
int net_write(lua_State* L, int id) {
	lua_getglobal(L, "write2data");
	lua_rawgeti(L, -1, id);
	
	int len;
	const char* buf = lua_tolstring(L, -1, &len);
	const int written = write(id, buf, len);
	lua_pop(L, 2);
	
	// written
	if (written > 0) {
		lua_getglobal(L, "onwrite");
		lua_pushinteger(L, id);
		lua_pushinteger(L, written);
		sas_call(L, 2, 0);
		
		// only read now
		struct epoll_event ev;
		ev.data.fd = id;
		ev.events = EPOLLET | EPOLLIN;
		
		int res = epoll_ctl(eid, EPOLL_CTL_MOD, id, &ev);
	}
	
	// close !
	else {
		puts("close write");
		close(id);
		lua_getglobal(L, "onclose");
		lua_pushinteger(L, id);
		sas_call(L, 0, 0);
	}
	return 0;
}

int net_read(lua_State* L, int id) {
	lua_getglobal(L, "isserver");
	lua_rawgeti(L, -1, id);
	int doesaccept = lua_toboolean(L, -1);
	lua_pop(L, 2);
	
	// accept
	if (doesaccept) {
		struct sockaddr_in in;
		int len = sizeof(in);
		const int cid = accept(id, (struct sockaddr*) &in, &len);
		
		if (cid >= 0) {
			lua_getglobal(L, "onaccept");
			lua_pushinteger(L, id);
			lua_pushinteger(L, cid);
			sas_call(L, 2, 0);
		}	
	}

	// recv
	else {
		char buf[0x1000];
		int len = read(id, buf, 0x1000);
	
		// data
		if (len > 0) {
			lua_getglobal(L, "onread");
			lua_pushinteger(L, id);
			lua_pushlstring(L, buf, len);
			sas_call(L, 2, 0);
		}
		
		// close
		else if (len == 0) {
			puts("close read");
			close(id);
			lua_getglobal(L, "onclose");
			lua_pushinteger(L, id);
			sas_call(L, 1, 0);
		}
		
		// error
		else {
			puts(strerror(errno));
		}
	}
}

int sas_write(lua_State* L) {
	int id = luaL_checkinteger(L, -1);
	struct epoll_event ev;
	ev.data.fd = id;
	ev.events = EPOLLET | EPOLLOUT;

	// lazy
	int res = epoll_ctl(eid, EPOLL_CTL_ADD, id, &ev);
	if (res == -1) { // && errno == EEXISTS
		ev.events |= EPOLLIN;
		res = epoll_ctl(eid, EPOLL_CTL_MOD, id, &ev);
	}

	if (res == -1) {
		lua_pushstring(L, strerror(errno));
		return lua_error(L);
	}
	else {
		lua_pushinteger(L, id);
		return 1;
	}
}

int sas_read(lua_State* L) {
	int id = luaL_checkinteger(L, -1);
	struct epoll_event ev;
	ev.data.fd = id;
	ev.events = EPOLLET | EPOLLIN;
	
		// lazy
	int res = epoll_ctl(eid, EPOLL_CTL_ADD, id, &ev);
	if (res == -1) { // && errno == EEXISTS
		ev.events |= EPOLLOUT;
		res = epoll_ctl(eid, EPOLL_CTL_MOD, id, &ev);
	}
	
	if (res == -1) {
		lua_pushstring(L, strerror(errno));
		return lua_error(L);
	}
	else {
		lua_pushinteger(L, id);
		return 1;
	}
}

int sas_close(lua_State* L) {
	int id = luaL_checkinteger(L, -1);
	int res = close(id);
	lua_pushinteger(L, res);
	return 1;
}

int satis_prompt(lua_State* L) {
	char buf[0x1000];
	int len = read(0,buf,0x1000);

	// console closed
	if (!len)
		return -1;

	sas_dosafe(L, buf, len);

	// prompt
	writel(1,PROMPT);

	return 0;
}


int main(int argc, char** argv) {
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

		// net
		{"read", sas_read},
		{"write", sas_write},
		{"close", sas_close},
		{0, 0},
	};
	luaL_newlib(L, lib);
	lua_setglobal(L, "sas");
	
	// protect
	lua_setglobal(L, "os");
	
	int r = sas_dofile(L, "lua/init.lua");
	if (r) {
		size_t len;
		const char* c = lua_tolstring(L,-1,&len);
		write(1,c,len);
	}

	// self-test
	if (argc == 2 && (!strcmp(argv[1], "-t") || !strcmp(argv[1], "--test"))) {
		sas_dofile(L, "test/text.lua");
		sas_dofile(L, "test/func.lua");
		sas_dofile(L, "test/http.lua");
		return 0;
	}
	
	// watches
	eid = epoll_create1(0);
	
	sas_dofile(L, "sas/main.lua");
	
	// prompt
	writel(1,PROMPT);

	struct epoll_event evs[0x20];

	while (1) {
		int num = epoll_wait(eid, evs, 0x20, -1);
		if (num <= 0) {
			printf("EPOLL ERROR %d: %s\n", num, strerror(errno));
			break;
		}

		for (int i = 0; i < num; i++) {
			if (evs[i].events & EPOLLOUT)
				net_write(L, evs[i].data.fd);
			if (evs[i].events & EPOLLIN)
				net_read(L, evs[i].data.fd);
		}
	}
	
	return 0;
}
