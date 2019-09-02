#include <lua.h>
#include <lauxlib.h>

#include "loc.h"

int xlua_append(lua_State* L, int aid, int bid);
void xlua_pushloc(lua_State* L, YYLTYPE loc);
int xlua_pushatoom(lua_State* L, char* text);
int xlua_reftekst(lua_State* L, char* str);
int xlua_refatoom(lua_State* L, char* text);
int xlua_reffn0(lua_State* L, int fid);
int xlua_reffn1(lua_State* L, int fid, int aid);
int xlua_reffn2(lua_State* L, int fid, int aid, int bid);
int xlua_reffn3(lua_State* L, int fid, int aid, int bid, int cid);
int xlua_reffn4(lua_State* L, int fid, int aid, int bid, int cid, int did);
int xlua_reffn5(lua_State* L, int fid, int aid, int bid, int cid, int did, int eid);

int lua_code(lua_State* L);
int lua_ontleed(lua_State* L);
//int yyerror(YYLTYPE* loc, lua_State* L, int* ref, void* scanner, const char* yymsg);
int lua_ontleedexp(lua_State* L);

/*
#include <string.h> 
#include ".taal.yy.h"
#include ".lex.yy.h"
#define LREG LUA_REGISTRYINDEX
*/
