#include <unistd.h>
#include <sys/syscall.h>
#include <limits.h>
#include <inttypes.h>

uint64_t atoi(uint64_t a, char* t) {
	if (a == 0) {
		t[0] = '0';
		return 1;
	}
	int len = 0;
	int p = 0;
	if (a < 0) {
		a = -a;
		t[len++] = '-';
		t[len++] = '-';
		p = 1;
	}
	while (a > 0) {
		int b = a % 10;
		t[len++] = b + '0';
		a /= 10;
	}
	for (int i = 0; i < len/2; i++) {
		int tt = t[i+p];
		t[i+p] = t[len-i-1+p];
		t[len-i-1+p] = tt;
	}

	return len;
}

int _start() {
	char data[(LONG_MAX%10)+1];
	int len = atoi(LONG_MAX,data);
	syscall(SYS_write, STDOUT_FILENO, data, len);
	syscall(SYS_exit, 0);
}
