#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "loc.h"
#include "lua.h"
#include ".taal.yy.h"
#include ".lex.yy.h"
#define LREG LUA_REGISTRYINDEX

void xlua_pushloc(lua_State* L, YYLTYPE loc) {
	lua_pushnil(L); return;
	lua_createtable(L, 0, 5);
	lua_pushinteger(L, loc.first_line + 1); lua_setfield(L, -2, "y1");
	lua_pushinteger(L, loc.first_column + 1); lua_setfield(L, -2, "x1");
	lua_pushinteger(L, loc.last_line + 1); lua_setfield(L, -2, "y2");
	lua_pushinteger(L, loc.last_column + 1 - 1); lua_setfield(L, -2, "x2");
	//lua_pushstring(L, loc.file); lua_setfield(L, -2, "bron");
}

int xlua_reflijst(lua_State*L, int oid, int aid, YYLTYPE loc) {
	// [](,(1 2)) 
	if (xlua_istupel(L, aid)) {
		lua_rawgeti(L, LREG, aid);
			lua_rawgeti(L, LREG, oid);
				lua_setfield(L, -2, "o");
			xlua_pushloc(L, loc);
				lua_setfield(L, -2, "loc");
			lua_pop(L, 1);
		luaL_unref(L, LREG, oid);
		return aid;
	}
	// [](1)
	else {
		lua_createtable(L, 1, 1);
			lua_rawgeti(L, LREG, oid);
				lua_setfield(L, -2, "o");
			lua_rawgeti(L, LREG, aid);
				lua_rawseti(L, -2, 1);
			lua_getfield(L, LREG, "code");
				lua_setfield(L, -2, "code");
			xlua_pushloc(L, loc);
				lua_setfield(L, -2, "loc");
			luaL_unref(L, LREG, oid);
			luaL_unref(L, LREG, aid);
			return luaL_ref(L, LREG);
		//
	}
}

int xlua_sluit(lua_State* L, int ref) {
	lua_rawgeti(L, LREG, ref);
		lua_pushnil(L);
			lua_setfield(L, -2, "open");
		lua_pop(L, 1);
	return ref;
}

int xlua_isopen(lua_State* L, int ref) {
	lua_rawgeti(L, LREG, ref);
		lua_getfield(L, -1, "open");
			int res = !lua_isnil(L, -1);
			lua_pop(L, 2);
		//
	//
	return res;
}


int xlua_istupel(lua_State* L, int ref) {
	lua_rawgeti(L, LREG, ref);
		lua_getfield(L, -1, "o");
			if (!lua_isnil(L, -1)) {
			lua_getfield(L, -1, "v");
				int a =  !strcmp(lua_tostring(L, -1), ",");
				lua_pop(L, 3);
				return a;
			//
			}
		//
	//
	return 0;
}

int utf8len(char* a) {
	if ((*a & 0x80) == 0x00) return 1;
	if ((*a & 0xE0) == 0xC0) return 2;
	if ((*a & 0xF0) == 0xE0) return 3;
	if ((*a & 0xF8) == 0xF0) return 4;
	return -1;
}

int utf8cp(char* a) {
	int l = utf8len(a);
	if (l == 1) return a[0] & 0x7F;
	if (l == 2) return ((a[0] & 0x1F) << 6) | (a[1] & 0x3F);
	if (l == 3) return ((a[0] & 0x0F) << 12) | ((a[1] & 0x3F) << 6) | (a[2] & 0x3F);
	if (l == 4) return ((a[0] & 0x07) << 18) | ((a[1] & 0x3F) << 12) | ((a[2] & 0x3F) << 6) | (a[2] & 0x3F);
	return -1;
}

int xlua_append(lua_State* L, int lijst, int el, YYLTYPE loc) {
	lua_rawgeti(L, LREG, lijst);
		int len = lua_objlen(L, -1);
		lua_rawgeti(L, LREG, el);
			lua_rawseti(L, -2, len + 1);
		//xlua_pushloc(L, loc);
			//lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
		//	lua_setfield(L, -2, "code");
		lua_pop(L, 1);
	luaL_unref(L, LREG, el);
	return lijst;
}

int xlua_appenda(lua_State* L, int lijst, int el, YYLTYPE loc) {
	lua_rawgeti(L, LREG, lijst);
		lua_getfield(L, -1, "a");
			int len = lua_objlen(L, -1);
			lua_rawgeti(L, LREG, el);
				lua_rawseti(L, -2, len + 1);
			xlua_pushloc(L, loc);
				//lua_setfield(L, -2, "loc");
			//lua_getfield(L, LREG, "code");
//				lua_setfield(L, -2, "code");
			lua_pop(L, 2);
		//
	//
	return lijst;
}

YYLTYPE locincrement(YYLTYPE loc, char* str) {
	int len = utf8len(str);
	loc.first_line = loc.last_line;
	loc.first_column = loc.last_column;

	if (*str == '\n') {
		loc.last_line ++;
		loc.last_column = 0;
	}
	else {
		int len = utf8len(str);
		loc.last_column += len;
	}
	return loc;
}

int xlua_reftekst(lua_State* L, char* str, YYLTYPE loc) {
	int t = xlua_refobj(L, xlua_refatoom(L, "[]u", loc), loc);

	int i = 0;
	int esc = 0;

	// karakter locatie
	YYLTYPE chloc = loc;
	chloc.last_line = chloc.first_line;
	chloc.last_column = chloc.first_column;

	for (char* s = str + 1; *(s + utf8len(s)); chloc = locincrement(chloc, s), s += utf8len(s), i++) {
		// UTF-8
		int cp = utf8cp(s);
		if (esc) {
			     if (cp == 'n') cp = '\n';
			else if (cp == 'r') cp = '\r';
			else if (cp == 't') cp = '\t';
			else if (cp == 'e') cp = 0x31;
			else if (cp == '0') cp = '\0';
			esc = 0;
		}
		else if (cp == '\\') {
			esc = 1;
			continue;
		}

		char ch[16];
		sprintf(ch, "%d", cp);

		int karakter = xlua_refatoom(L, ch, chloc);
		t = xlua_append(L, t, karakter, loc);
	}
	return t;
}

int xlua_pushatoom(lua_State* L, char* text, YYLTYPE loc) {
	// =  { v = $1 }
	lua_createtable(L, 0, 2);
		lua_pushstring(L, text);
			lua_setfield(L, -2, "v");
//		xlua_pushloc(L, loc);
//			lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
//			lua_setfield(L, -2, "code");
		return 1;
	//
}

int xlua_refatoom(lua_State* L, char* text, YYLTYPE loc) {
	// =  { v = $1 }
	lua_createtable(L, 0, 2);
		lua_pushstring(L, text);
			lua_setfield(L, -2, "v");
//		xlua_pushloc(L, loc);
//			lua_setfield(L, -2, "loc");
//		lua_getfield(L, LREG, "code");
//			lua_setfield(L, -2, "code");
		return luaL_ref(L, LREG);
	//
}

int xlua_metloc(lua_State* L, int aid, YYLTYPE loc) {
	return aid;
	lua_rawgeti(L, LREG, aid);
		xlua_pushloc(L, loc);
			lua_setfield(L, -2, "loc");
		lua_getfield(L, LREG, "code");
			lua_setfield(L, -2, "code");
		lua_pop(L, 1);
	return aid;
}

int xlua_pushkomma(lua_State* L);

// maak nieuw (leeg) object
// {loc=loc, o=fid}
int xlua_refobj(lua_State* L, int fid, YYLTYPE loc) {
	lua_createtable(L, 0, 2);
		//xlua_pushloc(L, loc);
		//	lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "o");
		return luaL_ref(L, LREG);
	//
}

int xlua_refobj1(lua_State* L, int oid, int aid, YYLTYPE loc) {
	int ref = 0;
	lua_createtable(L, 1, 1);
		lua_rawgeti(L, LREG, oid);
			lua_setfield(L, -2, "o");
		//xlua_pushloc(L, loc);
			//lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_rawgeti(L, LREG, aid);
			lua_rawseti(L, -2, 1);
		ref = luaL_ref(L, LREG);
	return ref;
}

int xlua_reffn1(lua_State* L, int fid, int aid, YYLTYPE loc) {
	int ref = 0;
	lua_createtable(L, 1, 1);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
//		xlua_pushloc(L, loc);
//			lua_setfield(L, -2, "loc");
//		lua_getfield(L, LREG, "code");
//			lua_setfield(L, -2, "code");
		lua_rawgeti(L, LREG, aid);
			lua_setfield(L, -2, "a");
		ref = luaL_ref(L, LREG);
	luaL_unref(L, LREG, fid);
	luaL_unref(L, LREG, aid);
	return ref;
}

int xlua_reffn2(lua_State* L, int fid, int aid, int bid, YYLTYPE loc) {
	lua_createtable(L, 2, 1);
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		//xlua_pushloc(L, loc);
			//lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_createtable(L, 2, 1);
			xlua_pushatoom(L, ",", loc);
				lua_setfield(L, -2, "o");
			//xlua_pushloc(L, loc);
				//lua_setfield(L, -2, "loc");
			//lua_getfield(L, LREG, "code");
				//lua_setfield(L, -2, "code");
			lua_rawgeti(L, LREG, aid);
				lua_rawseti(L, -2, 1);
			lua_rawgeti(L, LREG, bid);
				lua_rawseti(L, -2, 2);
			lua_setfield(L, -2, "a");
		luaL_unref(L, LREG, fid);
		luaL_unref(L, LREG, aid);
		luaL_unref(L, LREG, bid);
		return luaL_ref(L, LREG);
	//
}

int xlua_reftup2(lua_State* L, int fid, int aid, int bid, YYLTYPE loc) {
	lua_createtable(L, 2, 1);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "o");
		//xlua_pushloc(L, loc);
			//lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_rawgeti(L, LREG, aid);
			lua_rawseti(L, -2, 1);
		lua_rawgeti(L, LREG, bid);
			lua_rawseti(L, -2, 2);
		// open
		lua_pushboolean(L, 1);
			lua_setfield(L, -2, "open");
		luaL_unref(L, LREG, fid);
		luaL_unref(L, LREG, aid);
		luaL_unref(L, LREG, bid);
		return luaL_ref(L, LREG);
	//
}

int xlua_reffn3(lua_State* L, int fid, int aid, int bid, int cid, YYLTYPE loc) {
	lua_createtable(L, 3, 1);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		//xlua_pushloc(L, loc);
			//lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_createtable(L, 3, 1);
			xlua_pushatoom(L, ",", loc);
				lua_setfield(L, -2, "o");
			//xlua_pushloc(L, loc);
				//lua_setfield(L, -2, "loc");
			//lua_getfield(L, LREG, "code");
				//lua_setfield(L, -2, "code");
			lua_rawgeti(L, LREG, aid);
				lua_rawseti(L, -2, 1);
			lua_rawgeti(L, LREG, bid);
				lua_rawseti(L, -2, 2);
			lua_rawgeti(L, LREG, cid);
				lua_rawseti(L, -2, 3);
			lua_setfield(L, -2, "a");
		luaL_unref(L, LREG, fid);
		luaL_unref(L, LREG, aid);
		luaL_unref(L, LREG, bid);
		luaL_unref(L, LREG, cid);
		return luaL_ref(L, LREG);
	//
}

int xlua_reffn4(lua_State* L, int fid, int aid, int bid, int cid, int did, YYLTYPE loc) {
	lua_createtable(L, 4, 1);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		//xlua_pushloc(L, loc);
			//lua_setfield(L, -2, "loc");
		//lua_getfield(L, LREG, "code");
			//lua_setfield(L, -2, "code");
		lua_createtable(L, 4, 1);
			xlua_pushatoom(L, ",", loc);
				lua_setfield(L, -2, "o");
			//xlua_pushloc(L, loc);
				//lua_setfield(L, -2, "loc");
			//lua_getfield(L, LREG, "code");
				//lua_setfield(L, -2, "code");
			lua_rawgeti(L, LREG, aid);
				lua_rawseti(L, -2, 1);
			lua_rawgeti(L, LREG, bid);
				lua_rawseti(L, -2, 2);
			lua_rawgeti(L, LREG, cid);
				lua_rawseti(L, -2, 3);
			lua_rawgeti(L, LREG, did);
				lua_rawseti(L, -2, 4);
			lua_setfield(L, -2, "a");
		luaL_unref(L, LREG, fid);
		luaL_unref(L, LREG, aid);
		luaL_unref(L, LREG, bid);
		luaL_unref(L, LREG, cid);
		luaL_unref(L, LREG, did);
		return luaL_ref(L, LREG);
	//
}

int xlua_reffn5(lua_State* L, int fid, int aid, int bid, int cid, int did, int eid, YYLTYPE loc) {
	lua_createtable(L, 0, 1);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		xlua_pushloc(L, loc);
			lua_setfield(L, -2, "loc");
		lua_getfield(L, LREG, "code");
			lua_setfield(L, -2, "code");
		lua_createtable(L, 5, 1);
			xlua_pushatoom(L, ",", loc);
				lua_setfield(L, -2, "o");
			xlua_pushloc(L, loc);
				lua_setfield(L, -2, "loc");
			lua_getfield(L, LREG, "code");
				lua_setfield(L, -2, "code");
			lua_rawgeti(L, LREG, aid);
				lua_rawseti(L, -2, 1);
			lua_rawgeti(L, LREG, bid);
				lua_rawseti(L, -2, 2);
			lua_rawgeti(L, LREG, cid);
				lua_rawseti(L, -2, 3);
			lua_rawgeti(L, LREG, did);
				lua_rawseti(L, -2, 4);
			lua_rawgeti(L, LREG, eid);
				lua_rawseti(L, -2, 5);
			lua_setfield(L, -2, "a");
		luaL_unref(L, LREG, fid);
		luaL_unref(L, LREG, aid);
		luaL_unref(L, LREG, bid);
		luaL_unref(L, LREG, cid);
		luaL_unref(L, LREG, did);
		luaL_unref(L, LREG, eid);
		return luaL_ref(L, LREG);
	//
}

/*
void lua_pushlisp(lua_State* L, node* node) {
	// waarde
	lua_newtable(L);

	// locatie
	lua_pushliteral(L, "loc");
	lua_pushloc(L, node->loc);
	lua_settable(L, -3);

	// fout
	if (*node->fout) {
		lua_pushliteral(L, "fout");
		lua_pushstring(L, node->fout);
		lua_settable(L, -3);
	}

	// is tekst
	if (node->tekst) {
		lua_pushliteral(L, "tekst");
		lua_pushboolean(L, 1);
		lua_settable(L, -3);
	}

	if (node->exp) {
		// velden
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			if (i == 0)
				lua_pushliteral(L, "fn");
			else
				lua_pushinteger(L, i);
			lua_pushlisp(L, n);
			lua_settable(L, -3);
			i++;
		}
	} else {
		// data
		lua_pushliteral(L, "v");
		lua_pushstring(L, node->data);
		lua_settable(L, -3);
	}
}
*/

int lua_code(lua_State* L) {
	return 1;
}

lua_State* GL;

// ontleed(code [, bron])
int lua_ontleed(lua_State* L) {
	GL = L;
	// voeg '\n' aan het einde toe
	luaL_checkstring(L, 1);
	lua_pushvalue(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	lua_replace(L, 1);

	// bron
	char* file;
	if (lua_gettop(L) == 2)
		file = (char*)luaL_checkstring(L, 2);
	else
		file = "?";

	// code
	const char* code = luaL_checkstring(L, 1);

	lua_pushvalue(L, 1);
		lua_setfield(L, LREG, "code");
	//

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	int ref;
	lua_createtable(L, 0, 0);
	int fouten = luaL_ref(L, LREG);
	int ok = yyparse(L, &ref, &fouten, scanner);

	lua_pushnil(L);
		lua_setfield(L, LREG, "code");

	lua_rawgeti(L, LREG, ref);
	lua_rawgeti(L, LREG, fouten);

	yylex_destroy(scanner);

	return 2;
}

// ontleed(code [, bron])
int lua_ontleedexp(lua_State* L) {
	GL = L;
	// voeg '\n' aan het einde toe
	luaL_checkstring(L, 1);
	lua_pushvalue(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	lua_replace(L, 1);

	// code
	const char* code = luaL_checkstring(L, 1);

	lua_pushvalue(L, 1);
		lua_setfield(L, LREG, "code");
	//

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	int ref;
	lua_createtable(L, 0, 0);
	int fouten = luaL_ref(L, LREG);
	int ok = yyparse(L, &ref, &fouten, scanner);

	lua_pushnil(L);
		lua_setfield(L, LREG, "code");

	lua_rawgeti(L, LREG, ref);
		lua_getfield(L, -1, "a");
			lua_rawgeti(L, -1, 1);
				lua_remove(L, -2);
			lua_remove(L, -2);
		lua_rawgeti(L, LREG, fouten);
			yylex_destroy(scanner);
			return 2;
		//
	//
}

int yyerror(YYLTYPE* loc, lua_State* L, int* ref, int* fouten, void* scanner, const char* yymsg) {
	lua_createtable(L, 0, 3);
		lua_pushliteral(L, "syntax");
			lua_setfield(L, -2, "type");
		xlua_pushloc(L, *loc);
			lua_setfield(L, -2, "loc");
		lua_pushstring(L, yymsg);
			lua_setfield(L, -2, "fmt");
		int fout = luaL_ref(L, LREG);
	xlua_append(L, *fouten, fout, *loc);

	return 0;
}

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

EXPORT int luaopen_ontleed(lua_State* L) {
	lua_pushcfunction(L, lua_ontleed); lua_setglobal(L, "ontleed");
	lua_pushcfunction(L, lua_ontleedexp); lua_setglobal(L, "ontleedexp");
	return 1;
}

