#include <math.h>
#include <stdio.h>

int main() {
	volatile int a = -3;
	int b = abs(a);
	printf("%d\n", b);
	return 0;
}
