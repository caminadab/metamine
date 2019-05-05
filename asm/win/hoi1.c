#include <windows.h>

int __main() {
	WriteConsoleA(GetStdHandle(STD_OUTPUT_HANDLE), "hoi", 3, 0, 0);
	return 0;
}
