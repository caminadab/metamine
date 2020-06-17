	.file	"win.c"
	.intel_syntax noprefix
	.text
	.section .rdata,"dr"
	.align 2
.LC0:
	.ascii "S\0c\0h\0a\0a\0k\0 \0^&\0\0"
.LC4:
	.ascii "hoi\0"
	.text
	.globl	WindowProc
	.def	WindowProc;	.scl	2;	.type	32;	.endef
	.seh_proc	WindowProc
WindowProc:
	push	r14
	.seh_pushreg	r14
	push	r13
	.seh_pushreg	r13
	push	r12
	.seh_pushreg	r12
	sub	rsp, 192
	.seh_stackalloc	192
	.seh_endprologue
	mov	r12, rcx
	cmp	edx, 256
	je	.L2
	ja	.L3
	cmp	edx, 2
	je	.L4
	cmp	edx, 15
	jne	.L6
	lea	r14, 120[rsp]
	mov	rdx, r14
	call	[QWORD PTR __imp_BeginPaint[rip]]
	lea	rdx, 132[rsp]
	mov	r8d, 8
	mov	r13, rax
	mov	rcx, rax
	call	[QWORD PTR __imp_FillRect[rip]]
	lea	r9, 72[rsp]
	mov	rcx, r12
	mov	QWORD PTR 56[rsp], r9
	mov	rdx, r9
	call	[QWORD PTR __imp_GetClientRect[rip]]
	mov	r9, QWORD PTR 56[rsp]
	or	r8d, -1
	mov	rcx, r13
	lea	rdx, .LC0[rip]
	mov	DWORD PTR 32[rsp], 5
	call	[QWORD PTR __imp_DrawTextW[rip]]
	mov	ecx, 3277000
	call	[QWORD PTR __imp_CreateSolidBrush[rip]]
	mov	rcx, r13
	mov	rdx, rax
	call	[QWORD PTR __imp_SelectObject[rip]]
	movss	xmm1, DWORD PTR looptijd[rip]
	mov	rcx, r13
	mov	edx, 2
	movss	xmm0, DWORD PTR .LC1[rip]
	mov	eax, DWORD PTR muisX[rip]
	mov	QWORD PTR 88[rsp], 0
	inc	DWORD PTR i[rip]
	addss	xmm0, xmm1
	addss	xmm1, DWORD PTR .LC2[rip]
	mov	DWORD PTR 96[rsp], eax
	mov	eax, DWORD PTR muisY[rip]
	mov	DWORD PTR 104[rsp], 100
	mov	DWORD PTR 112[rsp], 0
	mov	DWORD PTR 100[rsp], eax
	cvttss2si	eax, xmm1
	movss	DWORD PTR looptijd[rip], xmm0
	divss	xmm0, DWORD PTR .LC3[rip]
	mov	DWORD PTR 108[rsp], eax
	cvttss2si	eax, xmm0
	mov	DWORD PTR 116[rsp], eax
	call	[QWORD PTR __imp_SetPolyFillMode[rip]]
	lea	rdx, 88[rsp]
	mov	r8d, 4
	mov	rcx, r13
	call	[QWORD PTR __imp_Polygon[rip]]
	mov	rdx, r14
	mov	rcx, r12
	call	[QWORD PTR __imp_EndPaint[rip]]
	mov	rdx, r13
	mov	rcx, r12
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
	mov	rcx, rax
	lea	rdx, .LC4[rip]
	call	[QWORD PTR __imp_WriteConsoleW[rip]]
	jmp	.L10
.L7:
	xor	r8d, r8d
	xor	edx, edx
	call	[QWORD PTR __imp_InvalidateRect[rip]]
	mov	r9d, 257
	xor	r8d, r8d
	xor	edx, edx
	mov	rcx, r12
	call	[QWORD PTR __imp_RedrawWindow[rip]]
	xor	r9d, r9d
	mov	r8d, 16
	xor	edx, edx
	mov	rcx, r12
	call	[QWORD PTR __imp_SetTimer[rip]]
.L10:
	xor	eax, eax
	jmp	.L1
.L6:
	mov	rcx, r12
	call	[QWORD PTR __imp_DefWindowProcW[rip]]
.L1:
	add	rsp, 192
	pop	r12
	pop	r13
	pop	r14
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 2
.LC5:
	.ascii "h\0o\0i\0\0\0"
	.align 2
.LC6:
	.ascii "h\0o\0i\0\12\0\0\0"
	.align 2
.LC7:
	.ascii "M\0e\0t\0a\0m\0i\0n\0e\0\0\0"
	.text
	.globl	WinMain
	.def	WinMain;	.scl	2;	.type	32;	.endef
	.seh_proc	WinMain
WinMain:
	push	r14
	.seh_pushreg	r14
	push	r13
	.seh_pushreg	r13
	push	r12
	.seh_pushreg	r12
	push	rdi
	.seh_pushreg	rdi
	push	rsi
	.seh_pushreg	rsi
	push	rbx
	.seh_pushreg	rbx
	sub	rsp, 264
	.seh_stackalloc	264
	.seh_endprologue
	xor	ebx, ebx
	mov	rsi, QWORD PTR __imp_LoadIconW[rip]
	movabs	rax, 27303570963759181
	movabs	rdx, 28429445101060205
	mov	r12, rcx
	mov	QWORD PTR 118[rsp], rax
	mov	ecx, 16
	mov	eax, ebx
	lea	rdi, 184[rsp]
	lea	r14, 118[rsp]
	mov	r13d, r9d
	mov	QWORD PTR 126[rsp], rdx
	rep stosd
	lea	rax, WindowProc[rip]
	mov	QWORD PTR 208[rsp], r12
	mov	edx, 32512
	mov	WORD PTR 134[rsp], 0
	mov	QWORD PTR 192[rsp], rax
	mov	QWORD PTR 248[rsp], r14
	call	rsi
	mov	edx, 32512
	xor	ecx, ecx
	mov	QWORD PTR 216[rsp], rax
	call	rsi
	mov	ecx, 65001
	mov	QWORD PTR 224[rsp], rax
	call	[QWORD PTR __imp_SetConsoleOutputCP[rip]]
	mov	rsi, QWORD PTR __imp_GetStdHandle[rip]
	mov	ecx, -11
	call	rsi
	xor	r9d, r9d
	mov	r8d, 3
	lea	rdx, .LC5[rip]
	mov	rdi, QWORD PTR __imp_WriteConsoleW[rip]
	mov	rcx, rax
	mov	QWORD PTR 32[rsp], 0
	call	rdi
	mov	ecx, -11
	call	rsi
	lea	r9, 100[rsp]
	mov	r8d, 4
	lea	rdx, .LC6[rip]
	mov	QWORD PTR 32[rsp], 0
	mov	rcx, rax
	call	rdi
	lea	rcx, 184[rsp]
	call	[QWORD PTR __imp_RegisterClassW[rip]]
	mov	QWORD PTR 80[rsp], r12
	mov	rdx, r14
	xor	ecx, ecx
	mov	QWORD PTR 88[rsp], 0
	mov	r9d, 13565952
	lea	r8, .LC7[rip]
	mov	QWORD PTR 72[rsp], 0
	mov	QWORD PTR 64[rsp], 0
	mov	DWORD PTR 56[rsp], -2147483648
	mov	DWORD PTR 48[rsp], -2147483648
	mov	DWORD PTR 40[rsp], -2147483648
	mov	DWORD PTR 32[rsp], -2147483648
	call	[QWORD PTR __imp_CreateWindowExW[rip]]
	mov	r12, rax
	test	rax, rax
	je	.L17
	lea	rdx, 104[rsp]
	xor	r9d, r9d
	mov	r8d, 16
	mov	rcx, rax
	mov	QWORD PTR 104[rsp], 1
	lea	rdi, 136[rsp]
	call	[QWORD PTR __imp_SetTimer[rip]]
	mov	rcx, r12
	mov	edx, r13d
	lea	r12, 136[rsp]
	call	[QWORD PTR __imp_ShowWindow[rip]]
	mov	eax, ebx
	mov	ecx, 12
	mov	rbx, QWORD PTR __imp_GetMessageW[rip]
	rep stosd
	mov	rsi, QWORD PTR __imp_TranslateMessage[rip]
	mov	rdi, QWORD PTR __imp_DispatchMessageW[rip]
.L14:
	xor	r9d, r9d
	xor	r8d, r8d
	xor	edx, edx
	mov	rcx, r12
	call	rbx
	test	eax, eax
	je	.L17
	mov	rcx, r12
	call	rsi
	mov	rcx, r12
	call	rdi
	jmp	.L14
.L17:
	xor	eax, eax
	add	rsp, 264
	pop	rbx
	pop	rsi
	pop	rdi
	pop	r12
	pop	r13
	pop	r14
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
.LC1:
	.long	1015580809
	.align 4
.LC2:
	.long	1140457472
	.align 4
.LC3:
	.long	1092616192
	.ident	"GCC: (GNU) 9.3-win32 20200324"
