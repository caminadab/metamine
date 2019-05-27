	.file	"a.c"
	.text
	.section	.rodata
.LC0:
	.string	"%f\n"
.LC2:
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
	subq	$64, %rsp
	movl	$182, -28(%rbp)
	movl	$9, -32(%rbp)
	movl	-28(%rbp), %edx
	movl	-32(%rbp), %eax
	movl	%eax, %ecx
	sall	%cl, %edx
	movl	%edx, %eax
	movl	%eax, -36(%rbp)
	movl	-36(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC0(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	$3, -4(%rbp)
	cvtsi2ss	-4(%rbp), %xmm0
	movss	%xmm0, -8(%rbp)
	cvtss2sd	-8(%rbp), %xmm1
	movsd	.LC1(%rip), %xmm0
	addsd	%xmm1, %xmm0
	cvtsd2ss	%xmm0, %xmm2
	movss	%xmm2, -8(%rbp)
	cvtss2sd	-8(%rbp), %xmm0
	leaq	.LC0(%rip), %rdi
	movl	$1, %eax
	call	printf@PLT
	movl	$10, -40(%rbp)
	movl	$8, -44(%rbp)
	movl	-44(%rbp), %eax
	cvtsi2sd	%eax, %xmm1
	movl	-40(%rbp), %eax
	cvtsi2sd	%eax, %xmm0
	call	pow@PLT
	cvttsd2si	%xmm0, %eax
	movl	%eax, -12(%rbp)
	movl	-12(%rbp), %eax
	movl	%eax, %esi
	leaq	.LC2(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movsd	.LC3(%rip), %xmm0
	movsd	%xmm0, -56(%rbp)
	movsd	.LC4(%rip), %xmm0
	movsd	%xmm0, -64(%rbp)
	movsd	-56(%rbp), %xmm1
	movsd	-64(%rbp), %xmm0
	addsd	%xmm1, %xmm0
	movsd	%xmm0, -24(%rbp)
	movsd	-24(%rbp), %xmm0
	leaq	.LC0(%rip), %rdi
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
.LC1:
	.long	858993459
	.long	1073951539
	.align 8
.LC3:
	.long	0
	.long	1073741824
	.align 8
.LC4:
	.long	0
	.long	1074266112
	.ident	"GCC: (Debian 8.3.0-7) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
