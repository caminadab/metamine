#include <math.h>
#include <stdio.h>

int _start() {
	volatile double A = 212312312.5;
	volatile double B = 3.5;
	int D = A + B;
	printf("%d %d\n", D, D);

	return 0;
}
