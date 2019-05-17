a ||= b
	memcpy(a.ptr + a.len, b.ptr, b.len)
	a[a.len..a.len+b.len] = b
	a.len += b.len

realloc a
	a.cap ·= 2
	a.ptr = realloc(a.ptr, a.cap · 2)

groei a
	a.ptr = realloc(a.ptr, a.cap)
	als niet a.ptr dan
	a.cap *= 2

alloc a
	bptr = a.ptr
	a.cap ·= 2
	a.ptr = realloc(0, a.cap)
	memcpy(a.ptr, bptr, b.len)

a || b
	len := a.len + b.len

	als len < a.cap dan
		a ||= b
	andersals len < b.cap dan
		b ||= a
	andersals dyn(a.ptr)
		a = groei a
		a ||= b
	anders
		a = alloc a
	
(ptr = byte[64], cap = 64, ptr(0..3)="hoi")
