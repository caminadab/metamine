#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include "node.h"

int numnodes;
node nodes[0x1000];

node* node_new() {
	node* new = &nodes[numnodes++];
	memset(new, 0, sizeof(node));
	return new;
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
	*out = 0;
	return out - out0;
}

node* a(char* t) {
	node* n = node_new();
	strcpy(n->data, t);
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

void print_node(node* n) {
	if (n->exp) {
		printf("(");
		for (node* kid = n->first; kid; kid = kid->next) {
			print_node(kid);
			if (kid->next)
				putchar(' ');
		}
		printf(")");
	}
	else {
		printf("%s", n->data);
	}
}

node* append(node* exp, node* atom) {
	if (exp == atom)
		puts("REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE");
	atom->root = exp;
	if (exp->last) {
		exp->last->next = atom;
		atom->prev = exp->last->next;
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
	a->root = n;
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
