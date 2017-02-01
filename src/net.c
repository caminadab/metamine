#include <lua5.2/lua.h>
#include <lua5.2/lauxlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

// tcp ipv4( ip, port )
int sas_client(lua_State* L) {
	int iplen;
	const char* ipstr = luaL_checklstring(L, -2, &iplen);
	int port = luaL_checkunsigned(L, -1);
	
	// create our socket
	int client = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	long nb = 1;
	ioctl(client, FIONBIO, &nb); 
	
	struct sockaddr_in in;
	inet_aton(ipstr, &in.sin_addr); // htonl?
	in.sin_port = htons(port);
	in.sin_family = AF_INET;
	
	connect(client, (struct sockaddr*) &in, sizeof(in));
	
	lua_pushinteger(L, client);
	return 1;
}
	
int sas_server(lua_State* L) {
	int port = luaL_checkinteger(L, -1);
	int server = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	long nb = 1;
	ioctl(server, FIONBIO, &nb); 
	struct sockaddr_in in;
	in.sin_addr.s_addr = 0;
	in.sin_port = htons(port);
	in.sin_family = AF_INET;
	int res = bind(server, (struct sockaddr*)&in, sizeof(in))
	|| listen(server, 99);
	if (res) {
		close(server);
		lua_pushnil(L);
		lua_pushliteral(L, "address already in use");
		return 2;
	}
	lua_pushinteger(L, server);
	return 1;
}
