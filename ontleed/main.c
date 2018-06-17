#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>
#include <lua.h>
#include <lauxlib.h>

typedef struct node node;
struct node {
	// kids?
	int exp;
	char data[0x100];
	node* first;
	node* last;
	node* next;
};

node* a(char* t);
extern node* yylval;
extern node* wortel;

struct fout {
	int lijn;
	char wat[0x1000];
};

extern int lijn;
extern int foutlen;
struct fout fouten[0x10];

#define NUM 258
//#define CAT 300

void yyerror (char const * s) {
	//fprintf(stderr, "%s\n", s);
}

int write_node(node* n, char* out, int left);
void yyparse();

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

	// tokens
	if (isalnum(c)) {
		int i;
		for (i = 0; i < 0x100 && (isalnum(c) || c == '-'); i++) {
			token[i] = c;
			c = *in++;
		}
		in--; //ungetc(c, stdin);
		token[i] = 0;
		yylval = a(token);
		return NUM;
	}

	// klaar
	if (!c)
		return 0;

	if (c == '\n')
		lijn++;

	token[0] = c;
	token[1] = 0;
	yylval = a(token);
	return c;
}

void lua_pushnode(lua_State* L, node* node) {
	if (node->exp) {
		lua_newtable(L);
		int i = 0;
		for (struct node* n = node->first; n; n = n->next) {
			lua_pushinteger(L, i+1);
			lua_pushnode(L, n);
			lua_settable(L,-3);
			i++;
		}
	} else {
		lua_pushstring(L, node->data);
	}
}

int ontleed(lua_State* L) {
	in = luaL_checkstring(L, 1);
	lijn = 0;
	foutlen = 0;
	yyparse();

	int r = 1;
	lua_pushnode(L, wortel);

	// fouten
	if (foutlen) {
		r++;
		lua_createtable(L, foutlen, 0);
		for (int i = 0; i < foutlen; i++) {
			lua_pushinteger(L, i+1);
			lua_pushinteger(L, fouten[i].lijn + 1);
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
	strcpy(buf, "a = 5 * 8\nb = a * 2 - 3 * - 8\n"); in = buf;
	yyparse();
	char out[1024];
	int len = write_node(wortel, out, 0x400);
	write(1, out, len);
	return 0;
}
