#include <lua.h>
#include <lauxlib.h>

#include "loc.h"

// exp = atoom | fn | obj
int xlua_istupel(lua_State* L, int ref);
int xlua_isopen(lua_State* L, int ref);
int xlua_sluit(lua_State* L, int ref);
int xlua_append(lua_State* L, int aid, int bid, YYLTYPE loc);
int xlua_appenda(lua_State* L, int aid, int bid, YYLTYPE loc);
int xlua_metloc(lua_State* L, int aid, YYLTYPE loc);
void xlua_pushloc(lua_State* L, YYLTYPE loc);
int xlua_pushatoom(lua_State* L, char* text, YYLTYPE loc);
int xlua_reftekst(lua_State* L, char* str, YYLTYPE loc);
int xlua_reflijst(lua_State*L, int oid, int aid, YYLTYPE loc);
int xlua_refatoom(lua_State* L, char* text, YYLTYPE loc);
int xlua_refobj(lua_State* L, int fid, YYLTYPE loc);
int xlua_refobj1(lua_State* L, int oid, int aid, YYLTYPE loc);
int xlua_reffn0(lua_State* L, int fid, YYLTYPE loc);
int xlua_reffn1(lua_State* L, int fid, int aid, YYLTYPE loc);
int xlua_reffn2(lua_State* L, int fid, int aid, int bid, YYLTYPE loc);
int xlua_reffn3(lua_State* L, int fid, int aid, int bid, int cid, YYLTYPE loc);
int xlua_reffn4(lua_State* L, int fid, int aid, int bid, int cid, int did, YYLTYPE loc);
int xlua_reffn5(lua_State* L, int fid, int aid, int bid, int cid, int did, int eid, YYLTYPE loc);
int xlua_reftup2(lua_State* L, int fid, int aid, int bid, YYLTYPE loc);

#define TN2 xlua_reftup2

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
