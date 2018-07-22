
typedef struct fout fout;
struct fout {
	int lijn;
	char bericht[0x1000];
};

extern struct fout fouten[0x10];

extern node* wortel;
extern int foutlen;
extern const char* in;
extern int lijn;
