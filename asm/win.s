	.file	"win.c"
	.section .rdata
.LC0:
	.ascii "ok\0"
.LC1:
	.ascii "hoi\0"
	.text
	.globl	__main
	.def	__main;	.scl	2;	.type	32;	.endef
__main:
	subq	$40, %rsp
	leaq	.LC0(%rip), %r8
	leaq	.LC1(%rip), %rdx
	xorl	%r9d, %r9d
	xorl	%ecx, %ecx
	call	*__imp_MessageBoxA(%rip)
	xorl	%eax, %eax
	addq	$40, %rsp
	ret
