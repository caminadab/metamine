#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#include "loc.h"
#include ".taal.yy.h"
#include ".lex.yy.h"
#define LREG LUA_REGISTRYINDEX

/*
	int yyerror(YYLTYPE* loc, void** root, struct fout* fouten, int* numfouten, int maxfouten, void* scanner, const char* yymsg) {
		if (*numfouten <= MAXFOUTEN) {
			struct fout* fout = &fouten[*numfouten];
			fout->loc = *loc; // loc
			if (*numfouten < MAXFOUTEN)
				strcpy(fout->msg, yymsg); //msg
			else
				strcpy(fout->msg, "teveel syntaxfouten");
			*numfouten += 1;
		}

	return 0;
}
*/

void lua_pushloc(lua_State* L, YYLTYPE loc) {
	lua_createtable(L, 0, 5);
	lua_pushinteger(L, loc.first_line + 1); lua_setfield(L, -2, "y1");
	lua_pushinteger(L, loc.first_column + 1); lua_setfield(L, -2, "x1");
	lua_pushinteger(L, loc.last_line + 1); lua_setfield(L, -2, "y2");
	lua_pushinteger(L, loc.last_column + 1 - 1); lua_setfield(L, -2, "x2");
	lua_pushstring(L, loc.file); lua_setfield(L, -2, "bron");
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

int xlua_append(lua_State* L, int lijst, int el) {
	// =  { v = $1 }
	lua_rawgeti(L, LREG, lijst);
		int len = lua_objlen(L, -1);
		lua_rawgeti(L, LREG, el);
		lua_rawseti(L, -2, len + 1);
	lua_pop(L, 1);
	return lijst;
}

int xlua_reftekst(lua_State* L, char* str) {
	int t = xlua_reffn0(L, xlua_refatoom(L, "[]u"));

	int i = 0;
	int esc = 0;
	for (char* s = str + 1; *(s + utf8len(s)); s += utf8len(s), i++) {
		// UTF-8
		int cp = utf8cp(s);
		if (esc) {
			     if (cp == 'n') cp = '\n';
			else if (cp == 'r') cp = '\r';
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
		//node* tekennode = aloc(ch, t->loc);
		//tekennode->loc.first_column += i;
		//tekennode->loc.last_column = tekennode->loc.first_column + 1; // TODO unicode & regeleinden
		int karakter = xlua_refatoom(L, ch);
		t = xlua_append(L, t, karakter);
	}
	return t;
}

int xlua_pushatoom(lua_State* L, char* text) {
	// =  { v = $1 }
	lua_createtable(L, 0, 1);
		lua_pushstring(L, text);
			lua_setfield(L, -2, "v");
	return 1;
}

int xlua_refatoom(lua_State* L, char* text) {
	// =  { v = $1 }
	lua_createtable(L, 0, 1);
		lua_pushstring(L, text);
			lua_setfield(L, -2, "v");
	int ref = luaL_ref(L, LREG);
	return ref;
}

int xlua_reffn0(lua_State* L, int fid) {
	int ref = 0;
	lua_createtable(L, 0, 1);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		ref = luaL_ref(L, LREG);
	return ref;
}

int xlua_reffn1(lua_State* L, int fid, int aid) {
	int ref = 0;
	lua_createtable(L, 0, 1);
	{
		lua_rawgeti(L, LREG, fid);
		{
			lua_setfield(L, -2, "f");
		}
		lua_rawgeti(L, LREG, aid);
		{
			lua_rawseti(L, -2, 1);
		}
		ref = luaL_ref(L, LREG);
	}
	return ref;
}

int xlua_reffn2(lua_State* L, int fid, int aid, int bid) {
	int ref = 0;
	lua_createtable(L, 0, 1);
	{
		//lua_pushstring(L, text);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		lua_rawgeti(L, LREG, aid);
			lua_rawseti(L, -2, 1);
		lua_rawgeti(L, LREG, bid);
			lua_rawseti(L, -2, 2);
		ref = luaL_ref(L, LREG);
	}
	return ref;
}

int xlua_reffn3(lua_State* L, int fid, int aid, int bid, int cid) {
	int ref = 0;
	lua_createtable(L, 0, 1);
	{
		//lua_pushstring(L, text);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		lua_rawgeti(L, LREG, aid);
			lua_rawseti(L, -2, 1);
		lua_rawgeti(L, LREG, bid);
			lua_rawseti(L, -2, 2);
		lua_rawgeti(L, LREG, cid);
			lua_rawseti(L, -2, 3);
		ref = luaL_ref(L, LREG);
	}
	return ref;
}

int xlua_reffn4(lua_State* L, int fid, int aid, int bid, int cid, int did) {
	int ref = 0;
	lua_createtable(L, 0, 1);
	{
		//lua_pushstring(L, text);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
		lua_rawgeti(L, LREG, aid);
			lua_rawseti(L, -2, 1);
		lua_rawgeti(L, LREG, bid);
			lua_rawseti(L, -2, 2);
		lua_rawgeti(L, LREG, cid);
			lua_rawseti(L, -2, 3);
		lua_rawgeti(L, LREG, did);
			lua_rawseti(L, -2, 4);
		ref = luaL_ref(L, LREG);
	}
	return ref;
}

int xlua_reffn5(lua_State* L, int fid, int aid, int bid, int cid, int did, int eid) {
	int ref = 0;
	lua_createtable(L, 0, 1);
	{
		//lua_pushstring(L, text);
		lua_rawgeti(L, LREG, fid);
			lua_setfield(L, -2, "f");
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
		ref = luaL_ref(L, LREG);
	}
	return ref;
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

	// bron (of "?")
	char* file = "?";
	if (lua_gettop(L) == 2)
		file = (char*)luaL_checkstring(L, 2);

	// code
	const char* code = luaL_checkstring(L, 1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(code, scanner);

	int ref;
	int ok = yyparse(L, &ref, scanner);
	lua_rawgeti(L, LREG, ref);
	//luaL_unref(L, LREG, wortel);
	yylex_destroy(scanner);


	// file fixen
	//setfile(wortel, file);

	lua_createtable(L, 0, 0);

	// fouten pushen
	/*lua_createtable(L, numfouten, 0);
	for (int i = 0; i < numfouten; i++) {
		// index
		lua_pushinteger(L, i+1);
		// fout
		lua_createtable(L, 0, 3);
		{
			// type
			lua_pushstring(L, "syntax");
			lua_setfield(L, -2, "type");
			// fmt
			lua_pushstring(L, fouten[i].msg);
			lua_setfield(L, -2, "fmt");
			// loc
			lua_pushloc(L, fouten[i].loc);
			lua_setfield(L, -2, "loc");
		}
		lua_settable(L, -3);
	}
	*/
	return 2;
}

int yyerror(YYLTYPE* loc, lua_State* L, int* ref, void* scanner, const char* yymsg) {
	puts(yymsg);
	return 0;
}

int lua_ontleedexp(lua_State* L) {
	luaL_checkstring(L, 1);
	lua_pushliteral(L, "\n");
	lua_concat(L, 2);
	const char* str = lua_tostring(L, -1);

	yyscan_t scanner;
	yylex_init(&scanner);
	yy_scan_string(str, scanner);

	int ref;
	yyparse(L, &ref, scanner);
	lua_rawgeti(L, LREG, ref);
	yylex_destroy(scanner);

	// file fixen
	//setfile(wortel, "<EXP>");
	lua_rawgeti(L, -1, 1);
	return 1;
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

