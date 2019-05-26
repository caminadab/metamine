#include <math.h>
#include <stdio.h>

int main() {
	int i0 = 3;
	float f0 = (float)i0;
	f0 += 2.4;
	printf("%f\n", f0);

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
