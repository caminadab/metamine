#include "node.h"

struct fout {
	YYLTYPE loc;
	char msg[256];
};

int ontleed(char* code, char* buf, int buflen, struct fout* fouten, int maxfouten);
