	.file	"hoi1.c"
	.text
	.def	__main;	.scl	2;	.type	32;	.endef
	.section .rdata,"dr"
.LC0:
	.ascii "hoi\0"
	.text
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	call	__main
	movl	$-11, %ecx
	movq	__imp_GetStdHandle(%rip), %rax
	call	*%rax
	movq	$0, 32(%rsp)
	movl	$0, %r9d
	movl	$3, %r8d
	leaq	.LC0(%rip), %rdx
	movq	%rax, %rcx
	movq	__imp_WriteConsoleA(%rip), %rax
	call	*%rax
	movl	$0, %eax
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.ident	"GCC: (GNU) 8.3-win32 20190406"
