	.file	"win.c"
	.intel_syntax noprefix
	.text
	.section .rdata,"dr"
.LC3:
	.ascii "hoi\0"
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
	sub	rsp, 160
	.seh_stackalloc	160
	.seh_endprologue
	mov	rbx, rcx
	cmp	edx, 256
	je	.L2
	ja	.L3
	cmp	edx, 2
	je	.L4
	cmp	edx, 15
	jne	.L6
	lea	rdi, 88[rsp]
	mov	rdx, rdi
	call	[QWORD PTR __imp_BeginPaint[rip]]
	mov	r8d, 8
	lea	rdx, 12[rdi]
	mov	rsi, rax
	mov	rcx, rax
	call	[QWORD PTR __imp_FillRect[rip]]
	mov	ecx, 3277000
	call	[QWORD PTR __imp_CreateSolidBrush[rip]]
	mov	rcx, rsi
	mov	rdx, rax
	call	[QWORD PTR __imp_SelectObject[rip]]
	movss	xmm1, DWORD PTR looptijd[rip]
	mov	rcx, rsi
	mov	edx, 2
	movss	xmm0, DWORD PTR .LC0[rip]
	mov	eax, DWORD PTR muisX[rip]
	mov	QWORD PTR 56[rsp], 0
	inc	DWORD PTR i[rip]
	addss	xmm0, xmm1
	addss	xmm1, DWORD PTR .LC1[rip]
	mov	DWORD PTR 64[rsp], eax
	mov	eax, DWORD PTR muisY[rip]
	mov	DWORD PTR 72[rsp], 100
	mov	DWORD PTR 80[rsp], 0
	mov	DWORD PTR 68[rsp], eax
	cvttss2si	eax, xmm1
	movss	DWORD PTR looptijd[rip], xmm0
	divss	xmm0, DWORD PTR .LC2[rip]
	mov	DWORD PTR 76[rsp], eax
	cvttss2si	eax, xmm0
	mov	DWORD PTR 84[rsp], eax
	call	[QWORD PTR __imp_SetPolyFillMode[rip]]
	lea	rdx, 56[rsp]
	mov	r8d, 4
	mov	rcx, rsi
	call	[QWORD PTR __imp_Polygon[rip]]
	mov	rdx, rdi
	mov	rcx, rbx
	call	[QWORD PTR __imp_EndPaint[rip]]
	mov	rdx, rsi
	mov	rcx, rbx
	call	[QWORD PTR __imp_ReleaseDC[rip]]
	jmp	.L10
.L3:
	cmp	edx, 275
	je	.L7
	cmp	edx, 512
	jne	.L6
	movzx	eax, r9w
	shr	r9d, 16
	mov	DWORD PTR muisX[rip], eax
	mov	DWORD PTR muisY[rip], r9d
	jmp	.L10
.L4:
	xor	ecx, ecx
	call	[QWORD PTR __imp_PostQuitMessage[rip]]
	jmp	.L10
.L2:
	mov	ecx, -11
	call	[QWORD PTR __imp_GetStdHandle[rip]]
	xor	r9d, r9d
	mov	QWORD PTR 32[rsp], 0
	mov	r8d, 3
	lea	rdx, .LC3[rip]
	mov	rcx, rax
	call	[QWORD PTR __imp_WriteConsoleW[rip]]
	jmp	.L10
.L7:
	xor	r8d, r8d
	xor	edx, edx
	call	[QWORD PTR __imp_InvalidateRect[rip]]
	mov	r9d, 258
	xor	r8d, r8d
	xor	edx, edx
	mov	rcx, rbx
	call	[QWORD PTR __imp_RedrawWindow[rip]]
	xor	r9d, r9d
	mov	r8d, 16
	xor	edx, edx
	mov	rcx, rbx
	call	[QWORD PTR __imp_SetTimer[rip]]
.L10:
	xor	eax, eax
	jmp	.L1
.L6:
	mov	rcx, rbx
	call	[QWORD PTR __imp_DefWindowProcW[rip]]
.L1:
	add	rsp, 160
	pop	rbx
	pop	rsi
	pop	rdi
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC5:
	.ascii "hoi\12\0"
	.align 2
.LC4:
	.ascii "M\0e\0t\0a\0m\0i\0n\0e\0\0\0"
	.text
	.globl	WinMain
	.def	WinMain;	.scl	2;	.type	32;	.endef
	.seh_proc	WinMain
WinMain:
	push	r13
	.seh_pushreg	r13
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
	sub	rsp, 264
	.seh_stackalloc	264
	.seh_endprologue
	mov	ax, WORD PTR .LC4[rip+16]
	xor	esi, esi
	mov	edx, 32512
	movups	xmm0, XMMWORD PTR .LC4[rip]
	mov	rbp, rcx
	mov	ecx, 16
	lea	rbx, 118[rsp]
	mov	r12d, r9d
	mov	WORD PTR 134[rsp], ax
	lea	rdi, 184[rsp]
	mov	eax, esi
	rep stosd
	lea	rax, WindowProc[rip]
	movups	XMMWORD PTR 118[rsp], xmm0
	mov	rdi, QWORD PTR __imp_LoadIconW[rip]
	mov	QWORD PTR 248[rsp], rbx
	mov	QWORD PTR 192[rsp], rax
	mov	QWORD PTR 208[rsp], rbp
	call	rdi
	mov	edx, 32512
	xor	ecx, ecx
	mov	QWORD PTR 216[rsp], rax
	call	rdi
	mov	ecx, 65001
	mov	QWORD PTR 224[rsp], rax
	call	[QWORD PTR __imp_SetConsoleOutputCP[rip]]
	mov	ecx, -11
	mov	r13, QWORD PTR __imp_GetStdHandle[rip]
	call	r13
	xor	r9d, r9d
	mov	r8d, 3
	lea	rdx, .LC3[rip]
	mov	rcx, rax
	mov	rdi, QWORD PTR __imp_WriteConsoleW[rip]
	mov	QWORD PTR 32[rsp], 0
	call	rdi
	mov	ecx, -11
	call	r13
	lea	r9, 100[rsp]
	mov	r8d, 4
	lea	rdx, .LC5[rip]
	mov	QWORD PTR 32[rsp], 0
	mov	rcx, rax
	call	rdi
	lea	rcx, 184[rsp]
	call	[QWORD PTR __imp_RegisterClassW[rip]]
	mov	rdx, rbx
	mov	QWORD PTR 80[rsp], rbp
	xor	ecx, ecx
	mov	QWORD PTR 88[rsp], 0
	mov	r9d, 13565952
	lea	r8, .LC4[rip]
	mov	QWORD PTR 72[rsp], 0
	mov	QWORD PTR 64[rsp], 0
	mov	DWORD PTR 56[rsp], -2147483648
	mov	DWORD PTR 48[rsp], -2147483648
	mov	DWORD PTR 40[rsp], -2147483648
	mov	DWORD PTR 32[rsp], -2147483648
	call	[QWORD PTR __imp_CreateWindowExW[rip]]
	mov	rbx, rax
	test	rax, rax
	je	.L17
	lea	rdx, 104[rsp]
	xor	r9d, r9d
	mov	r8d, 16
	mov	rcx, rax
	mov	QWORD PTR 104[rsp], 1
	lea	rdi, 136[rsp]
	call	[QWORD PTR __imp_SetTimer[rip]]
	mov	rcx, rbx
	mov	edx, r12d
	lea	rbx, 136[rsp]
	call	[QWORD PTR __imp_ShowWindow[rip]]
	mov	eax, esi
	mov	ecx, 12
	mov	rsi, QWORD PTR __imp_GetMessageW[rip]
	rep stosd
	mov	rbp, QWORD PTR __imp_DispatchMessageW[rip]
	mov	rdi, QWORD PTR __imp_TranslateMessage[rip]
.L14:
	xor	r9d, r9d
	xor	r8d, r8d
	xor	edx, edx
	mov	rcx, rbx
	call	rsi
	test	eax, eax
	je	.L17
	mov	rcx, rbx
	call	rdi
	mov	rcx, rbx
	call	rbp
	jmp	.L14
.L17:
	xor	eax, eax
	add	rsp, 264
	pop	rbx
	pop	rsi
	pop	rdi
	pop	rbp
	pop	r12
	pop	r13
	ret
	.seh_endproc
	.globl	looptijd
	.bss
	.align 4
looptijd:
	.space 4
	.globl	i
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
	.section .rdata,"dr"
	.align 4
.LC0:
	.long	1015580809
	.align 4
.LC1:
	.long	1140457472
	.align 4
.LC2:
	.long	1092616192
	.ident	"GCC: (GNU) 8.3-win32 20191201"
