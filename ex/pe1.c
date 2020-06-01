#include <stdio.h>

int main() {
	int s = 0;
	for (int i = 0; i < 10000000; i++) {
		if (i % 3 == 0 || i % 5 == 0)
			s += i;
	}
	printf("%d\n", s);
	return 0;
}
		
