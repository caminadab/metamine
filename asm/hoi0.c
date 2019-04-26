#include <unistd.h>
#include <sys/syscall.h>

char getallen[0x100] = "hoi\n";

int _start() {
	getallen[0] = 'H';
	syscall(SYS_write, STDOUT_FILENO, getallen, 4);
	syscall(SYS_exit, 0);
}
