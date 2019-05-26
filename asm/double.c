#include <math.h>
#include <stdio.h>

int main() {
	volatile int a = 10;
	volatile int b = 8;
	int c = pow(a, b);
	printf("%d\n", c);

	volatile double A = 2.0;
	volatile double B = 3.0;
	double C = A + B;
	printf("%f\n", C);

	return 0;
}
