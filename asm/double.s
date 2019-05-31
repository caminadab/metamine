	.file	"double.c"
	.section	.rodata
.LC2:
	.string	"%f\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	.LC0(%rip), %rax
	movq	%rax, -16(%rbp)
	movq	.LC1(%rip), %rax
	movq	%rax, -24(%rbp)
	fldl	-16(%rbp)
	fldl	-24(%rbp)
	faddp	%st, %st(1)
	fstpl	-40(%rbp)
	fldl	-40(%rbp)
	fstpl	-8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, -40(%rbp)
	movlps	-40(%rbp), %xmm0
	leaq	.LC2(%rip), %rdi
	movl	$1, %eax
	call	printf@PLT
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.section	.rodata
	.align 8
.LC0:
	.long	0
	.long	1073741824
	.align 8
.LC1:
	.long	0
	.long	1074266112
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
