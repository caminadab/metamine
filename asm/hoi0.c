#include <unistd.h>
#include <sys/syscall.h>

int _start() {
	syscall(SYS_write, STDOUT_FILENO, "hoi\n", 4);
	syscall(SYS_exit, 0);
}
