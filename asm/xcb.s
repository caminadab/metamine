	.file	"xcb.c"
	.text
	.globl	_start
	.type	_start, @function
_start:
.LFB6:
	.cfi_startproc
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	orq	$-1, %rcx
	xorl	%esi, %esi
	movabsq	$6350124331664434504, %rax
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	subq	$56, %rsp
	.cfi_def_cfa_offset 112
	movq	%rax, 36(%rsp)
	leaq	36(%rsp), %r15
	xorl	%eax, %eax
	leaq	20(%rsp), %r12
	movl	$2179651, 44(%rsp)
	movq	%r15, %rdi
	repnz scasb
	xorl	%edi, %edi
	movq	%rcx, %rdx
	notq	%rdx
	leaq	-1(%rdx), %rax
	movq	%rax, 8(%rsp)
	movabsq	$5629585436180520, %rax
	movq	%rax, 28(%rsp)
	call	xcb_connect@PLT
	movq	%rax, %rdi
	movq	%rax, %rbx
	call	xcb_get_setup@PLT
	movq	%rax, %rdi
	call	xcb_setup_roots_iterator@PLT
	movq	%rbx, %rdi
	movq	%rax, %r13
	movl	(%rax), %ebp
	call	xcb_generate_id@PLT
	movq	%r12, %r8
	movl	$65540, %ecx
	movq	%rbx, %rdi
	movl	%eax, 4(%rsp)
	movl	12(%r13), %eax
	movl	%ebp, %edx
	movl	4(%rsp), %esi
	movl	$0, 24(%rsp)
	movl	%eax, 20(%rsp)
	call	xcb_create_gc@PLT
	movq	%rbx, %rdi
	call	xcb_generate_id@PLT
	movl	%ebp, %edx
	movq	%r12, %r8
	movl	$65544, %ecx
	movl	%eax, %r14d
	movl	8(%r13), %eax
	movq	%rbx, %rdi
	movl	$0, 24(%rsp)
	movl	%r14d, %esi
	movl	%eax, 20(%rsp)
	call	xcb_create_gc@PLT
	movq	%rbx, %rdi
	call	xcb_generate_id@PLT
	xorl	%r9d, %r9d
	xorl	%r8d, %r8d
	movq	%rbx, %rdi
	movl	%eax, %ebp
	movl	8(%r13), %eax
	movl	$32769, 24(%rsp)
	movl	%ebp, %edx
	movl	%eax, 20(%rsp)
	pushq	%rsi
	.cfi_def_cfa_offset 120
	xorl	%esi, %esi
	pushq	%r12
	.cfi_def_cfa_offset 128
	pushq	$2050
	.cfi_def_cfa_offset 136
	movl	32(%r13), %eax
	pushq	%rax
	.cfi_def_cfa_offset 144
	pushq	$1
	.cfi_def_cfa_offset 152
	pushq	$10
	.cfi_def_cfa_offset 160
	pushq	$150
	.cfi_def_cfa_offset 168
	pushq	$150
	.cfi_def_cfa_offset 176
	movl	0(%r13), %ecx
	call	xcb_create_window@PLT
	addq	$64, %rsp
	.cfi_def_cfa_offset 112
	movl	%ebp, %esi
	movq	%rbx, %rdi
	call	xcb_map_window@PLT
	movq	%rbx, %rdi
	leaq	28(%rsp), %r13
	call	xcb_flush@PLT
.L2:
	movq	%rbx, %rdi
	call	xcb_wait_for_event@PLT
	movq	%rax, %r12
	testq	%rax, %rax
	je	.L3
	movzbl	(%r12), %eax
	andb	$127, %al
	cmpl	$2, %eax
	je	.L3
	cmpl	$12, %eax
	jne	.L4
	movl	4(%rsp), %edx
	movq	%r13, %r8
	movl	$1, %ecx
	movl	%ebp, %esi
	movq	%rbx, %rdi
	call	xcb_poly_rectangle@PLT
	movl	%r14d, %ecx
	movl	%ebp, %edx
	movl	$20, %r9d
	pushq	%rax
	.cfi_def_cfa_offset 120
	movl	$20, %r8d
	movq	%rbx, %rdi
	pushq	%r15
	.cfi_def_cfa_offset 128
	movl	24(%rsp), %esi
	call	xcb_image_text_8@PLT
	movq	%rbx, %rdi
	call	xcb_flush@PLT
	popq	%rdx
	.cfi_def_cfa_offset 120
	popq	%rcx
	.cfi_def_cfa_offset 112
.L4:
	movq	%r12, %rdi
	call	free@PLT
	jmp	.L2
.L3:
	addq	$56, %rsp
	.cfi_def_cfa_offset 56
	xorl	%eax, %eax
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE6:
	.size	_start, .-_start
	.ident	"GCC: (Debian 8.3.0-7) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
