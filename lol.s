	.file	"lol.c"
	.globl	a
	.data
	.align 32
	.type	a, @object
	.size	a, 4000
a:
	.long	1
	.long	2
	.long	3
	.zero	3988
	.section	.rodata
.LC0:
	.string	"%d\n"
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
	subq	$16, %rsp
	movl	$0, -4(%rbp)
	movl	$10, -8(%rbp)
	jmp	.L2
.L3:
	movl	-8(%rbp), %eax
	subl	$1, %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	a(%rip), %rax
	movl	(%rdx,%rax), %eax
	leal	1(%rax), %ecx
	movl	-8(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	a(%rip), %rax
	movl	%ecx, (%rdx,%rax)
	movl	-8(%rbp), %eax
	subl	$10, %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	a(%rip), %rax
	movl	(%rdx,%rax), %eax
	addl	%eax, -4(%rbp)
	addl	$1, -8(%rbp)
.L2:
	cmpl	$999, -8(%rbp)
	jle	.L3
	movl	-4(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC0(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
