#include "taal.yy.h"

typedef struct node node;

struct node {
	// kids?
	int exp;
	char data[0x1000]; // max tekst data!
	node* root;
	node* first;
	node* last;
	node* next;
	node* prev;

	// hehehe
	int off, len;

	YYLTYPE loc;
};

extern int numnodes;
extern node nodes[0x10000];

void print_loc(YYLTYPE loc);

node* fn3(node* a, node* b, node* c, YYLTYPE loc);

node* karakter(int ch);
node* node_new();
int write_node(node* n, char* out, int left);
void print_node(node* n);

// maak ze
node* append(node* exp, node* atom);
node* exp0();
node* exp1(node* a);
node* _exp2(node* a, node* b);
node* exp3(node* a, node* b, node* c);
node* exp4(node* a, node* b, node* c, node* d);
void node_assign(node* new, node* old);
node* node_copy(node* orig);
node* tekst(node* str);
node* a(char* t);

// met locatie
node* appendloc(node* exp, node* atom, YYLTYPE yylloc);
node* fn0loc(YYLTYPE yylloc);
node* fn1loc(node* a, YYLTYPE yylloc);
node* fn2loc(node* a, node* b, YYLTYPE yylloc);
node* fn3loc(node* a, node* b, node* c, YYLTYPE yylloc);
node* fn4loc(node* a, node* b, node* c, node* d, YYLTYPE yylloc);
//void node_assign(node* new, node* old);
//node* node_copy(node* orig);
node* tekstloc(node* str, YYLTYPE yylloc);
node* aloc(char* t, YYLTYPE yylloc);
node* metloc(node* n, YYLTYPE yylloc);
