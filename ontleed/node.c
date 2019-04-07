#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include "node.h"

int numnodes;
node nodes[0x10000];
#define max(a,b) ((a) > (b) ? (a) : (b))
#define min(a,b) ((a) < (b) ? (a) : (b))

node* node_new() {
	node* new = &nodes[numnodes++];
	memset(new, 0, sizeof(node));
	return new;
}

void print_loc(YYLTYPE loc) {
	if (loc.first_line == loc.last_line && loc.first_column == loc.last_column)
		printf("%d:%d", loc.first_line+1, loc.first_column+1);
	else if (loc.first_line == loc.last_line)
		printf("%d:%d-%d", loc.first_line+1, loc.first_column+1, loc.last_column+1);
	else
		printf("%d:%d-%d:%d", loc.first_line+1, loc.first_column+1, loc.last_line+1, loc.last_column+1);
}

int write_node(node* n, char* out, int left) {
	char* out0 = out;
	if (n->exp) {
		int a = 1;
		for (node* kid = n->first; kid; kid = kid->next) {
			out += write_node(kid, out, left);
			if (a) {
				*out++ = '(';
				a = 0;
			}
			else if (kid->next)
				*out++ = ' ';
		}
		*out++ = ')';
	}
	else {
		int len = strlen(n->data);
		memcpy(out, n->data, len);
		out += len;
	}
	*out = 0;
	return out - out0;
}

node* a(char* t) {
	node* n = node_new();
	strcpy(n->data, t);
	return n;
}

node* aloc(char* t, YYLTYPE yylloc) {
	node* n = a(t);
	n->loc = yylloc;
	return n;
}

void node_assign(node* new, node* old) {
	/*if (old->prev) old->prev->next = new;
	if (old->next) old->next->prev = new;
	if (old->root) {
		if (old->root->first == old) old->root->first = new;
		if (old->root->last == old) old->root->last = new;
	}
	memcpy(new, old, sizeof(node));
	*/
	new->first = old->first;
	new->last = old->last;
	new->exp = old->exp;
	new->loc = old->loc;
	strcpy(new->data, old->data);

	// fix parents
	for (node* n = new->first; n; n = n->next)
		n->root = new;
}

node* node_copy(node* orig) {
	node* copy = node_new();
	node_assign(copy, orig);
	return copy;
}

void print_node_sub(node* n) {
	if (n->exp) {
		int a = 1;
		for (node* kid = n->first; kid; kid = kid->next) {
			print_node_sub(kid);
			if (a) {
				a = 0;
				printf("(");
			}

			if (kid->next && kid->prev)
				putchar(' ');
		}
		printf(")");
	}
	else {
		printf("%s", n->data);
	}
	printf(" [");
	print_loc(n->loc);
	printf("]");
}

void print_node(node* n) {
	print_node_sub(n);
	printf("\n");
}

node* append(node* exp, node* atom) {
	if (exp == atom)
		puts("REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE");

	// converteer naar fn
	if (!exp->exp) {
		node_assign(exp, fn1loc(aloc(exp->data, exp->loc), exp->loc));
	}

	atom->root = exp;

	if (exp->last) {
		node* vorige_laatste = exp->last;
		exp->last = atom;

		vorige_laatste->next = atom;
		atom->prev = exp->last->next;
		atom->next = false;
		
	} else {
		exp->first = atom;
		exp->last = atom;
		atom->prev = false;
		atom->next = false;
	}
	return exp;
}

node* prepend(node* atom, node* exp) {
	if (exp == atom)
		puts("REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE");

	// converteer naar fn
	if (!exp->exp) {
		exp = exp1(exp);
	}

	atom->root = exp;

	if (exp->first) {
		exp->first->prev = atom;
		atom->next = exp->first;
		exp->first = atom;
	} else {
		exp->first = atom;
		exp->last = atom;
	}
	print_node(exp);
	return exp;
}

node* karakter(int ch) {
	char buf[16];
	sprintf(buf, "%d", ch);
	return a(buf);
}

node* tekst(node* str0) {
	char* str = str0->data;
	node* t = exp1(a("[]"));
	t->loc = str0->loc;
	for (int i = 1; str[i+1]; i++) {
		char ch[16];
		//itoa(str[i], 
		sprintf(ch, "%d", str[i]);
		node* tekennode = aloc(ch, t->loc);
		tekennode->loc.first_column += i;
		tekennode->loc.last_column = tekennode->loc.first_column + 1; // TODO unicode & regeleinden
		t = append(t, tekennode);

	}
	return t;
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
	a->root = n;
	a->prev = false;
	a->next = false;
	return n;
}

node* _exp2(node* a, node* b) {
	node* n = node_new();
	n->exp = true;
	n->first = a;
	n->last = b;
	a->next = b; b->prev = a;
	a->root = b->root = n;
	return n;
}

node* exp3(node* a, node* b, node* c) {
	node* n = node_new();
	n->exp = true;
	n->first = a;
	n->last = c;
	a->next = b; b->prev = a;
	b->next = c; c->prev = b;
	a->root = b->root = c->root = n;
	return n;
}

node* exp4(node* a, node* b, node* c, node* d) {
	node* n = node_new();
	n->exp = true;
	n->first = a;
	n->last = d;
	a->next = b; b->prev = a;
	b->next = c; c->prev = b;
	c->next = d; d->prev = c;
	a->root = b->root = c->root = d->root = n;
	return n;
}

node* exp5(node* a, node* b, node* c, node* d, node* e) {
	node* n = node_new();
	n->exp = true;
	n->first = a;
	n->last = e;
	a->next = b; b->prev = a;
	b->next = c; c->prev = b;
	c->next = d; d->prev = c;
	d->next = e; e->prev = d;
	a->root = b->root = c->root = d->root = e->root = n;
	return n;
}

//YYLTYPE lmin(YYLTYPE a, YYLTYPE b) {
YYLTYPE mix(YYLTYPE a, YYLTYPE b) {
	YYLTYPE c;

	// lijn
	c.first_line = min(a.first_line, b.first_line);
	c.last_line = max(a.last_line, b.last_line);

	// kolombegin
	if (a.first_line < b.first_line)
		c.first_column = a.first_column;
	else if (a.first_line > b.first_line)
		c.first_column = b.first_column;
	else if (a.first_line == b.first_line)
		c.first_column = min(a.first_column, b.first_column);

	// kolomeinde
	if (a.last_line > b.last_line)
		c.last_column = a.last_column;
	else if (a.last_line < b.last_line)
		c.last_column = b.last_column;
	else if (a.last_line == b.last_line)
		c.last_column = max(a.last_column, b.last_column);

	return c;
}

YYLTYPE mix3(YYLTYPE a, YYLTYPE b, YYLTYPE c) {
	return mix(mix(a,b),c);
}
YYLTYPE mix4(YYLTYPE a, YYLTYPE b, YYLTYPE c, YYLTYPE d) {
	return mix(mix(mix(a,b),c),d);
}
YYLTYPE mix5(YYLTYPE a, YYLTYPE b, YYLTYPE c, YYLTYPE d, YYLTYPE e) {
	return mix(mix(mix(mix(a,b),c),d),e);
}

node* appendloc(node* exp, node* atom, YYLTYPE yylloc) {
	node* n = append(exp,atom);
	n->loc = mix(exp->loc, atom->loc);
	//n->loc.first_line = exp->loc.first_line;
	//n->loc.first_column = exp->loc.first_column;
	//n->loc.last_line = atom->loc.last_line;
	//n->loc.last_column = atom->loc.last_column;
	return n;
}
node* prependloc(node* atom, node* exp, YYLTYPE yylloc) {
	node* n = prepend(atom,exp);
	n->loc = mix(exp->loc, atom->loc);
	//n->loc.first_line = exp->loc.first_line;
	//n->loc.first_column = exp->loc.first_column;
	//n->loc.last_line = atom->loc.last_line;
	//n->loc.last_column = atom->loc.last_column;
	return n;
}
node* fn0loc(YYLTYPE yylloc) {
	node* a = exp0();
	a->loc = yylloc;
}
node* fn1loc(node* a, YYLTYPE yylloc) {
	node* n = exp1(a);
	n->loc = yylloc;
	return n;
}
node* fn2loc(node* a, node* b, YYLTYPE yylloc) {
	node* n = _exp2(a,b);
	n->loc = mix(a->loc, b->loc);
	return n;
}
node* fn3loc(node* a, node* b, node* c, YYLTYPE yylloc) {
	node* n = exp3(a, b, c);
	n->loc = mix3(a->loc, b->loc, c->loc);
	return n;
}
node* fn4loc(node* a, node* b, node* c, node* d, YYLTYPE yylloc) {
	node* n = exp4(a,b,c,d);
	n->loc = mix4(a->loc, b->loc, c->loc, d->loc);
	return n;
}
node* fn5loc(node* a, node* b, node* c, node* d, node* e, YYLTYPE yylloc) {
	node* n = exp5(a,b,c,d,e);
	n->loc = mix5(a->loc, b->loc, c->loc, d->loc, e->loc);
	return n;
}
node* metloc(node* n, YYLTYPE yylloc) {
	n->loc = yylloc;
	return n;
}
node* metfout(node* n, char* fout) {
	strcpy(&n->fout, fout);
	return n;
}

//void node_assign(node* new, node* old);
//node* node_copy(node* orig);
node* tekstloc(node* str, YYLTYPE yylloc) {
	node* a = tekst(str);
	a->loc = yylloc;
	return a;
}
