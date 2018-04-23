/* Infix notation calculator.  */

%{
  #include <math.h>
  #include <stdio.h>
	#include <string.h>

  int yylex (void);
  void yyerror (char const *);

	// nodes
	typedef struct node node;
	struct node {
		char data[0x100];
		node* kid;
		node* next;
	};
	node nodes[0x1000];
	int numnodes = 0;

	node* node_new() {
		return &nodes[numnodes++];
	}

	void write_node(node* n) {
		if (n->kid) {
			printf("(");
			for (node* kid = n->kid; kid; kid = kid->next) {
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

	node* lisp3(node* a, node* b, node* c) {
		node* n = node_new();
		n->kid = a;
		a->next = b;
		b->next = c;
		return n;
	}

	node* lisp2(node* a, node* b) {
		node* n = node_new();
		n->kid = a;
		a->next = b;
		return n;
	}

%}

/* Bison declarations.  */
%define api.value.type {node*}
%token NUM
%token NAME
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

eq: exp '=' exp				{ $$ = lisp3(a("="), $1, $3); }

exp:
  NUM                { $$ = $1; }
| exp '^' exp        { $$ = lisp3(a("^"), $1, $3); }
| exp '*' exp        { $$ = lisp3(a("*"), $1, $3); }
| exp '/' exp        { $$ = lisp3(a("/"), $1, $3); }
| exp '+' exp        { $$ = lisp3(a("+"), $1, $3); }
| exp '-' exp        { $$ = lisp3(a("-"), $1, $3); }
| '-' exp  %prec NEG { $$ = lisp2(a("-"), $2); }
| '(' exp ')'				 { $$ = $2; }
;
