#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>
#include <lua.h>
#include <lauxlib.h>

#include "node.h"
#include "taal.h"

extern node* yylval;
extern node* wortel;

typedef struct fout fout;
struct fout {
	int lijn;
	char bericht[0x1000];
};

extern int lijn;
extern int foutlen;
struct fout fouten[0x10];

void yyerror (char const * s) {
	//fprintf(stderr, "%s\n", s);
}

char token[0x100];
char buf[0x1000];
const char* in;

int yylex(void) {
	int c;

	// wit overslaan
	while (1) {
		while ((c = *in++) == ' ' || c == '\t')
			continue;
		while (c == ';') {
			while ((c = *in++) != '\n')
				continue;
			lijn++;
			c = *in++;
		}
		if (c != ' ' && c != '\t' && c != ';')
			break;
	}

	const char* cc = in - 1;

	// naam
	if (isalnum(c)) {
		int i;
		for (i = 0; i < 0x100 && (isalnum(c) || c == '-'); i++) {
			token[i] = c;
			c = *in++;
		}
		in--;
		token[i] = 0;
		yylval = a(token);
		return NAME;
	}

	// klaar
	if (!c)
		return 0;

	if (c == '\n')
		lijn++;

	// multi-symbool
	int id;
	if (!strcmp(cc, "->"))			{ strcpy(token, "->"); id = TO; }
	else if (!strcmp(cc, "||")) { strcpy(token, "||"); id = CAT; }
	else if (!strcmp(cc, "..")) { strcpy(token, ".."); id = TIL; }
	else if (!strcmp(cc, "xx")) { strcpy(token, "xx"); id = CART; }
	else {
		token[0] = c;
		token[1] = 0;
		id = c;
	}
	yylval = a(token);
	return id;
}

void lua_pushnode(lua_State* L, node* node) {
	if (node->exp) {
		lua_newtable(L);
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			lua_pushinteger(L, i+1);
			lua_pushnode(L, n);
			lua_settable(L, -3);
			i++;
		}
	} else {
		lua_pushstring(L, node->data);
	}
}

void lua_pushfout(lua_State* L, fout fout) {
	lua_createtable(L, 0, 2);
	lua_pushinteger(L, fout.lijn + 1);
	lua_setfield(L, -2, "lijn");
	lua_pushstring(L, fout.bericht);
	lua_setfield(L, -2, "bericht");
}

// niet threadsafe lol
int ontleed(lua_State* L) {
	in = luaL_checkstring(L, 1);
	lijn = 0;
	foutlen = 0;
	numnodes = 0;
	yyparse();

	int r = 1;
	lua_pushnode(L, wortel);

	// fouten
	if (foutlen) {
		r++;
		lua_createtable(L, foutlen, 0);
		for (int i = 0; i < foutlen; i++) {
			lua_pushinteger(L, i+1);
			lua_pushfout(L, fouten[i]);
			lua_settable(L, -3);
		}
	}
	return r;
}

int luaopen_ontleed(lua_State* L) {
	in = luaL_checkstring(L, 1);
	lua_pushcfunction(L, ontleed);
	lua_setglobal(L, "ontleed");
	return 1;
}

int main() {
	strcpy(buf, "*");
	in = buf;
	yyparse();
	char out[1024];
	int len = write_node(wortel, out, 0x400);
	write(1, out, len);
	return 0;
}

extern int yydebug = 1;
