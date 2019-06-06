	.file	"abs.c"
	.text
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"%d\n"
	.section	.text.startup,"ax",@progbits
	.p2align 4,,15
	.globl	main
	.type	main, @function
main:
.LFB11:
	.cfi_startproc
	subq	$24, %rsp
	.cfi_def_cfa_offset 32
	leaq	.LC0(%rip), %rdi
	movl	$-3, 12(%rsp)
	movl	12(%rsp), %esi
	movl	%esi, %eax
	sarl	$31, %eax
	xorl	%eax, %esi
	subl	%eax, %esi
	xorl	%eax, %eax
	call	printf@PLT
	xorl	%eax, %eax
	addq	$24, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE11:
	.size	main, .-main
	.ident	"GCC: (Debian 8.3.0-7) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
