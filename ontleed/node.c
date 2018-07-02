#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include "node.h"

int numnodes;
node nodes[0x1000];

node* node_new() {
	node* new = &nodes[numnodes++];
	memset(new, 0, sizeof(node));
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
	strcpy(n->data, t);
	return n;
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
