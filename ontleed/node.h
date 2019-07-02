#pragma once
#define MAXFOUTEN 10

typedef struct node node;
typedef struct node* YYSTYPE;

#define YYLTYPE_IS_DECLARED
typedef struct YYLTYPE  
{  
	int first_line;  
	int first_column;  
	int last_line;  
	int last_column;  
	char* file;
} YYLTYPE;

struct node {
	// kids?
	int exp;
	char data[0x1000]; // max tekst data!
	node* root;
	node* first;
	node* last;
	node* next;
	node* prev;

	// foutbericht
	char fout[0x100];

	// is dit tekst?
	int tekst;

	// locatie
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
node* prepend(node* exp, node* atom);
node* exp0();
node* exp1(node* a);
node* _exp2(node* a, node* b);
node* exp3(node* a, node* b, node* c);
node* exp4(node* a, node* b, node* c, node* d);
node* exp5(node* a, node* b, node* c, node* d, node* e);
void node_assign(node* new, node* old);
node* node_copy(node* orig);
node* tekst(node* str);
node* a(char* t);

// met locatie
node* appendloc(node* exp, node* atom, YYLTYPE yylloc);
node* prependloc(node* atom, node* exp, YYLTYPE yylloc);
node* fn0loc(YYLTYPE yylloc);
node* fn1loc(node* a, YYLTYPE yylloc);
node* fn2loc(node* a, node* b, YYLTYPE yylloc);
node* fn3loc(node* a, node* b, node* c, YYLTYPE yylloc);
node* fn4loc(node* a, node* b, node* c, node* d, YYLTYPE yylloc);
node* fn5loc(node* a, node* b, node* c, node* d, node* e, YYLTYPE yylloc);
//void node_assign(node* new, node* old);
//node* node_copy(node* orig);
node* tekstloc(node* str, YYLTYPE yylloc);
node* aloc(char* t, YYLTYPE yylloc);
node* abron(char* t, char* bron);
node* metloc(node* n, YYLTYPE yylloc);
node* tekstmetloc(node* n, YYLTYPE yylloc);
node* metfout(node* n, char* fout);

// locatie zelf
YYLTYPE mix(YYLTYPE a, YYLTYPE b);
YYLTYPE mix3(YYLTYPE a, YYLTYPE b, YYLTYPE c);
YYLTYPE mix4(YYLTYPE a, YYLTYPE b, YYLTYPE c, YYLTYPE d);
YYLTYPE mix5(YYLTYPE a, YYLTYPE b, YYLTYPE c, YYLTYPE d, YYLTYPE e);
