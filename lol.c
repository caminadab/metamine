int a[1000] = {1, 2, 3};

int main() {
	int s = 0;
	for (int i = 10; i < 1000; i++) {
		a[i] = a[i-1] + 1;
		s += a[i-10];
	}
	printf("%d\n", s);
	return 0;
}
