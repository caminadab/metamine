#include <stdio.h>
#include <inttypes.h>

uint64_t fib(uint64_t n) {
	if (n == 0 || n == 1)
		return n;
	else
		return fib(n-1) + fib(n-2);
}

int main() {
	uint64_t n = 10;
	uint64_t a = fib(n);
	printf("fib(10) = %d\n", a);
	return 0;
}
