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
};

extern int numnodes;
extern node nodes[0x10000];

node* node_new();
int write_node(node* n, char* out, int left);
node* a(char* t);
void print_node(node* n);
node* append(node* exp, node* atom);
node* exp0();
node* exp1(node* a);
node* _exp2(node* a, node* b);
node* exp3(node* a, node* b, node* c);
node* exp4(node* a, node* b, node* c, node* d);
void node_assign(node* new, node* old);
node* node_copy(node* orig);
node* tekst(node* str);
