	.file	"hoi1.c"
	.intel_syntax noprefix
	.text
	.section .rdata,"dr"
.LC0:
	.ascii "hoi\0"
	.text
	.globl	__main
	.def	__main;	.scl	2;	.type	32;	.endef
	.seh_proc	__main
__main:
	sub	rsp, 56
	.seh_stackalloc	56
	.seh_endprologue
	mov	ecx, -11
	call	[QWORD PTR __imp_GetStdHandle[rip]]
	xor	r9d, r9d
	mov	r8d, 3
	lea	rdx, .LC0[rip]
	mov	rcx, rax
	mov	QWORD PTR 32[rsp], 0
	call	[QWORD PTR __imp_WriteConsoleA[rip]]
	xor	eax, eax
	add	rsp, 56
	ret
	.seh_endproc
	.ident	"GCC: (GNU) 8.3-win32 20191201"
