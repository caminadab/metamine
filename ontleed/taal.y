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
	node* wortel;

	node* node_new() {
		return &nodes[numnodes++];
	}

	void print_node(node* n) {
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

	int write_node(node* n, char* out, int left) {
		char* out0 = out;
		if (n->exp) {
			*out++ = '(';
			for (node* kid = n->first; kid; kid = kid->next) {
				out += write_node(kid, out, left);
				if (kid->next)
					*out++ = ' ';
			}
			*out++ = ')';
		}
		else {
			int len = strlen(n->data);
			memcpy(out, n->data, len);
			out += len;
		}
		return out - out0;
	}

	node* a(char* t) {
		node* n = node_new();
		strcpy(&n->data, t);
		return n;
	}

	node* append(node* exp, node* atom) {
		if (exp->last) {
			exp->last->next = atom;
			exp->last = atom;
		} else {
			exp->first = atom;
			exp->last = atom;
		}
		return exp;
	}

	node* exp0() {
		node* n = node_new();
		n->exp = true;
		n->first = 0;
		n->last = 0;
		return n;
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
/*%token CAT 300	"||"*/
%precedence NU
/*%left CAT*/
/*%left '<' '=' '>'*/
%left '-' '+'
%left '*' '/'
%precedence NEG
%right '^'
%left '.'

%%

input:
  %empty							{ $$ = wortel = exp0(); /*$$ = wortel;*/ }
| input eq						{ $$ = append($1, $2); }
| input '\n'					{ $$ = $1; }
;

eq: exp '=' exp				{ $$ = exp3(a("="), $1, $3); }

single:
	NUM
|	'(' exp ')'					{ $$ = $2; }
| '[' list ']'				{ $$ = $2; }
;

exp:
	single
| exp '+' exp       	{ $$ = exp3(a("+"), $1, $3); }
| exp '^' exp       	{ $$ = exp3(a("^"), $1, $3); }
| exp '*' exp       	{ $$ = exp3(a("*"), $1, $3); }
| exp '/' exp       	{ $$ = exp3(a("/"), $1, $3); }
| exp '+' exp       	{ $$ = exp3(a("+"), $1, $3); }
| exp '-' exp       	{ $$ = exp3(a("-"), $1, $3); }
| '-' exp  %prec NEG	{ $$ = _exp2(a("-"), $2); }

/*| exp CAT exp       	{ $$ = exp3(a("||"), $1, $3); }*/
| exp '|' '|' exp       	{ $$ = exp3(a("||"), $1, $4); }
| exp '.' '.' exp       	{ $$ = exp3(a(".."), $1, $4); }

| exp '.' exp       	{ $$ = exp3(a("."), $1, $3); }
/*| exp single exp			{ $$ = exp3($2, $1, $3); }*/
| single single					{ $$ = _exp2($1, $2); }
| exp '>' exp					{ $$ = _exp2($1, $3); }
;

list:
	%empty							{ $$ = exp1(a("[]")); }
|	items
;

items:
	exp									{ $$ = _exp2(a("[]"), $1); }
| items ',' exp				{ $$ = append($1, $3); }
;
