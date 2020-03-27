	.file	"win.c"
	.intel_syntax noprefix
	.text
	.globl	WindowProc
	.def	WindowProc;	.scl	2;	.type	32;	.endef
	.seh_proc	WindowProc
WindowProc:
	push	rdi
	.seh_pushreg	rdi
	push	rsi
	.seh_pushreg	rsi
	push	rbx
	.seh_pushreg	rbx
	sub	rsp, 144
	.seh_stackalloc	144
	.seh_endprologue
	mov	rsi, rcx
	cmp	edx, 15
	je	.L2
	cmp	edx, 512
	je	.L3
	cmp	edx, 2
	jne	.L4
	xor	ecx, ecx
	call	[QWORD PTR __imp_PostQuitMessage[rip]]
	jmp	.L6
.L3:
	movzx	eax, r9w
	shr	r9d, 16
	mov	DWORD PTR muisX[rip], eax
	mov	DWORD PTR muisY[rip], r9d
	jmp	.L6
.L2:
	lea	rdi, 72[rsp]
	mov	rdx, rdi
	call	[QWORD PTR __imp_BeginPaint[rip]]
	mov	r8d, 6
	lea	rdx, 12[rdi]
	mov	rbx, rax
	mov	rcx, rax
	call	[QWORD PTR __imp_FillRect[rip]]
	mov	ecx, 3277000
	call	[QWORD PTR __imp_CreateSolidBrush[rip]]
	mov	rcx, rbx
	mov	rdx, rax
	call	[QWORD PTR __imp_SelectObject[rip]]
	mov	eax, DWORD PTR i[rip]
	mov	ecx, DWORD PTR muisX[rip]
	mov	QWORD PTR 40[rsp], 0
	mov	edx, DWORD PTR muisY[rip]
	mov	DWORD PTR 52[rsp], 0
	lea	r8d, 1[rax]
	add	ecx, 100
	imul	eax, eax, 100
	add	edx, 500
	mov	DWORD PTR i[rip], r8d
	mov	DWORD PTR 56[rsp], ecx
	mov	rcx, rbx
	mov	DWORD PTR 60[rsp], edx
	mov	edx, 2
	add	eax, 400
	mov	DWORD PTR 48[rsp], eax
	mov	eax, 125
	sal	rax, 34
	mov	QWORD PTR 64[rsp], rax
	call	[QWORD PTR __imp_SetPolyFillMode[rip]]
	lea	rdx, 40[rsp]
	mov	r8d, 4
	mov	rcx, rbx
	call	[QWORD PTR __imp_Polygon[rip]]
	mov	rdx, rdi
	mov	rcx, rsi
	call	[QWORD PTR __imp_EndPaint[rip]]
	mov	rdx, rbx
	mov	rcx, rsi
	call	[QWORD PTR __imp_ReleaseDC[rip]]
.L6:
	xor	eax, eax
	jmp	.L1
.L4:
	call	[QWORD PTR __imp_DefWindowProcW[rip]]
.L1:
	add	rsp, 144
	pop	rbx
	pop	rsi
	pop	rdi
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC1:
	.ascii "hoi\12\0"
	.align 2
.LC2:
	.ascii "L\0e\0a\0r\0n\0 \0t\0o\0 \0P\0r\0o\0g\0r\0a\0m\0 \0W\0i\0n\0d\0o\0w\0s\0\0\0"
	.align 2
.LC0:
	.ascii "S\0a\0m\0p\0l\0e\0 \0W\0i\0n\0d\0o\0w\0 \0C\0l\0a\0s\0s\0\0\0"
	.text
	.globl	WinMain
	.def	WinMain;	.scl	2;	.type	32;	.endef
	.seh_proc	WinMain
WinMain:
	push	r12
	.seh_pushreg	r12
	push	rbp
	.seh_pushreg	rbp
	push	rdi
	.seh_pushreg	rdi
	push	rsi
	.seh_pushreg	rsi
	push	rbx
	.seh_pushreg	rbx
	sub	rsp, 272
	.seh_stackalloc	272
	.seh_endprologue
	lea	rsi, .LC0[rip]
	mov	edx, 32512
	mov	r12, QWORD PTR __imp_LoadIconW[rip]
	mov	rbp, rcx
	lea	rdi, 112[rsp]
	mov	ecx, 10
	mov	ebx, r9d
	rep movsd
	xor	esi, esi
	lea	rdi, 200[rsp]
	mov	ecx, 16
	mov	eax, esi
	rep stosd
	lea	rax, WindowProc[rip]
	lea	rdi, 112[rsp]
	mov	QWORD PTR 224[rsp], rbp
	mov	QWORD PTR 208[rsp], rax
	mov	QWORD PTR 264[rsp], rdi
	call	r12
	mov	edx, 32512
	xor	ecx, ecx
	mov	QWORD PTR 232[rsp], rax
	call	r12
	mov	ecx, -11
	mov	QWORD PTR 240[rsp], rax
	call	[QWORD PTR __imp_GetStdHandle[rip]]
	lea	r9, 108[rsp]
	mov	r8d, 4
	lea	rdx, .LC1[rip]
	mov	QWORD PTR 32[rsp], 0
	mov	rcx, rax
	call	[QWORD PTR __imp_WriteConsoleW[rip]]
	lea	rcx, 200[rsp]
	call	[QWORD PTR __imp_RegisterClassW[rip]]
	xor	ecx, ecx
	mov	QWORD PTR 80[rsp], rbp
	mov	rdx, rdi
	mov	QWORD PTR 88[rsp], 0
	mov	r9d, 13565952
	lea	r8, .LC2[rip]
	mov	QWORD PTR 72[rsp], 0
	mov	QWORD PTR 64[rsp], 0
	mov	DWORD PTR 56[rsp], -2147483648
	mov	DWORD PTR 48[rsp], -2147483648
	mov	DWORD PTR 40[rsp], -2147483648
	mov	DWORD PTR 32[rsp], -2147483648
	call	[QWORD PTR __imp_CreateWindowExW[rip]]
	test	rax, rax
	je	.L13
	mov	edx, ebx
	mov	rcx, rax
	lea	rdi, 152[rsp]
	call	[QWORD PTR __imp_ShowWindow[rip]]
	mov	eax, esi
	mov	ecx, 12
	mov	rsi, QWORD PTR __imp_GetMessageW[rip]
	rep stosd
	mov	rbp, QWORD PTR __imp_DispatchMessageW[rip]
	mov	rdi, QWORD PTR __imp_TranslateMessage[rip]
	lea	rbx, 152[rsp]
.L10:
	xor	r9d, r9d
	xor	r8d, r8d
	xor	edx, edx
	mov	rcx, rbx
	call	rsi
	test	eax, eax
	je	.L13
	mov	rcx, rbx
	call	rdi
	mov	rcx, rbx
	call	rbp
	jmp	.L10
.L13:
	xor	eax, eax
	add	rsp, 272
	pop	rbx
	pop	rsi
	pop	rdi
	pop	rbp
	pop	r12
	ret
	.seh_endproc
	.globl	i
	.bss
	.align 4
i:
	.space 4
	.globl	muisY
	.align 4
muisY:
	.space 4
	.globl	muisX
	.align 4
muisX:
	.space 4
	.ident	"GCC: (GNU) 8.3-win32 20191201"
