#include <stdio.h>
#include <string.h>

char* ontleed(char* code);

int test() {
	char* tests[][2] = {
		{"a = 1", "((= a 1))"},
		{"a = b + 1", "((= a (+ b 1)))"},
		{"b = f(a)", "((= b (f a)))"},
		{"b = f a", "((= b (f a)))"},
		{"a = (p => b)", "((= a (=> p b)))"},
		{"a : getal", "((: a getal))"},
		{"a = (b > c)", "((= a (> b c)))"},
		{"a = (b of c)", "((= a (of b c)))"},
		{"(a > 0) => b := 3", "((=> (> a 0) (:= b 3)))"},

		// funcs
		{"f = a -> a", "((= f (-> (, a) a)))"},
		{"f = a -> a + 1", "((= f (-> (, a) (+ a 1))))"},
		{"f = a,b -> c", "((= f (-> (, a b) c)))"},
		{"f = int,int -> int", "((= f (-> (, int int) int)))"},
		{"f = (intd,intd) -> intq", "((= f (-> (, intd intd) intq)))"},
		{"f = (int^2,int^2) -> int", "((= f (-> (, (^ int 2) (^ int 2)) int)))"},
		
		// blok
		{
			"a = {\n\t0 -> 1\n\tbeeld dt -> a(net) + dt\n}",
			"((= a ({} (-> 0 1) (-> (beeld dt) (+ (a net) dt))))"
		},

		// logica
		{"a = goed en lekker", "((= a (en goed lekker)))"},
		{"a = niet goed", "((= a (niet goed)))"},

		// fouten
		{"a = (3 =)", "((= a fout))"},
		{"a = 3\nb b b\nc = 0", "((= a 3) fout (= c 0))"},

		// procent
		{"a = 99% - 22%", "((= a (- (% 99) (% 22))))"},
		{"a = sin 10%", "((= a (sin (% 10))))"},
		{"a = -10% ^ b", "((= a (- (^ (% 10) b)))))"},

		// partieel
		{"a := 0", "((:= a 0))"},
		{"a += 0", "((+= a 0))"},

		// lijst
		{"a = []", "((= a ([])))"},
		{"a = [0]", "((= a ([] 0)))"},
		{"a = [1,2]", "((= a ([] 1 2)))"},
		{"a = 100 * [a,a]", "((= a (* 100 ([] a a))))"},

		// set
		{"a = {}", "((= a ({})))"},
		{"a = {1,2}", "((= a ({} 1 2)))"},
		{"a = {b => c}", "((= a ({} (=> b c))))"},
		//{"a = {b => c, d => e}", "((= a ({} (=> b c) (=> d e))))"},

		// hist
		{"a = b'", "((= a (' b)))"},
		{"a = (a' + 1)", "((= a (+ (' a) 1)))"},
		{"a = sin 10'", "((= a (sin (' 10))))"},

		// multi
		{"a = b | c + 2", "((= a (| b (+ c 2))))"},

		// operatoren
		{"a = (+)", "((= a +))"},
		{"a = (*)", "((= a *))"},

		// tekst
		{"a = \"hoi\"", "((= a ([] 104 111 105)))"},
		{"\"hoi\" = a", "((= ([] 104 111 105) a))"},

		{0, 0},
	};

	int fout = 0, totaal = 0;

	for (int i = 0; tests[i][0]; i++) {
		char* test = tests[i][0];
		char* doel = tests[i][1];
		char* lisp = ontleed(test);
		if (strcmp(lisp, doel)) {
			printf("%s != %s\n", lisp, doel);
			fout++;
		}
		totaal++;
	}
	printf("%d/%d fout\n", fout, totaal);
}
