/* Infix notation calculator.  */

%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

  int yylex (void);
  void yyerror (char const *);

	// nodes
	typedef struct node node;
	struct node {
		// kids?
		int exp;
		char data[0x100];
		node* first;
		node* last;
		node* next;
	};
	node nodes[0x1000];
	int numnodes = 0;

	node* node_new() {
		return &nodes[numnodes++];
	}

	void write_node(node* n) {
		if (n->exp) {
			printf("(");
			for (node* kid = n->first; kid; kid = kid->next) {
				write_node(kid);
				if (kid->next)
					putchar(' ');
			}
			printf(")");
		}
		else {
			printf("%s", n->data);
		}
	}

	node* a(char* t) {
		node* n = node_new();
		strcpy(&n->data, t);
		return n;
	}

	node* append(node* exp, node* atom) {
		exp->last->next = atom;
		exp->last = atom;
	}

	node* exp1(node* a) {
		node* n = node_new();
		n->exp = true;
		n->first = a;
		n->last = a;
		return n;
	}

	node* _exp2(node* a, node* b) {
		node* n = node_new();
		n->exp = true;
		n->first = a;
		n->last = b;
		a->next = b;
		return n;
	}

	node* exp3(node* a, node* b, node* c) {
		node* n = node_new();
		n->exp = true;
		n->first = a;
		n->last = c;
		a->next = b;
		b->next = c;
		return n;
	}

	node* exp4(node* a, node* b, node* c, node* d) {
		node* n = node_new();
		n->exp = true;
		n->first = a;
		n->last = d;
		a->next = b;
		b->next = c;
		c->next = d;
		return n;
	}

%}

/* Bison declarations.  */
%define api.value.type {node*}
%token NUM
%token NAME
%left '~'
%left '-' '+'
%left '*' '/'
%precedence NEG   /* negation--unary minus */
%right '^'        /* exponentiation */

%%

input:
  %empty
| input line
;

line:
  '\n'
|	eq 	{ putchar('\t'); write_node($$); putchar('\n'); }
;

eq: exp '=' exp				{ $$ = exp3(a("="), $1, $3); }

exp:
  NUM
| exp '~' exp       	{ $$ = exp3(a("~"), $1, $3); }
| exp '^' exp       	{ $$ = exp3(a("^"), $1, $3); }
| exp '*' exp       	{ $$ = exp3(a("*"), $1, $3); }
| exp '/' exp       	{ $$ = exp3(a("/"), $1, $3); }
| exp '+' exp       	{ $$ = exp3(a("+"), $1, $3); }
| exp '-' exp       	{ $$ = exp3(a("-"), $1, $3); }
| '-' exp  %prec NEG	{ $$ = _exp2(a("-"), $2); }
| '(' exp ')'					{ $$ = $2; }

| '[' list ']'				{ $$ = $2; }
;

list:
	%empty							{ $$ = exp1(a("[]")); }
|	items
;

items:
	exp									{ $$ = _exp2(a("[]"), $1); }
| items ',' exp				{ $$ = append($1, $3); }
;
