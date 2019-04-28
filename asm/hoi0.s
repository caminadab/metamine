	.file	"hoi0.c"
	.intel_syntax noprefix
	.text
	.p2align 4,,15
	.globl	atoi
	.type	atoi, @function
atoi:
.LFB4:
	.cfi_startproc
	test	rdi, rdi
	je	.L2
	movabs	r9, -3689348814741910323
	mov	ecx, 1
	jmp	.L3
	.p2align 4,,10
	.p2align 3
.L8:
	mov	rdi, rdx
.L3:
	mov	rax, rdi
	mov	r10, rdi
	mov	r8d, ecx
	mul	r9
	shr	rdx, 3
	lea	rax, [rdx+rdx*4]
	add	rax, rax
	sub	r10, rax
	mov	rax, r10
	add	eax, 48
	mov	BYTE PTR -1[rsi+rcx], al
	add	rcx, 1
	cmp	rdi, 9
	ja	.L8
	mov	ecx, r8d
	movsx	rax, r8d
	sar	ecx
	je	.L11
	lea	r8, -2[rsi+rax]
	sub	ecx, 1
	lea	rdx, -1[rsi+rax]
	sub	r8, rcx
	.p2align 4,,10
	.p2align 3
.L6:
	movzx	ecx, BYTE PTR [rsi]
	movzx	edi, BYTE PTR [rdx]
	sub	rdx, 1
	add	rsi, 1
	mov	BYTE PTR -1[rsi], dil
	mov	BYTE PTR 1[rdx], cl
	cmp	r8, rdx
	jne	.L6
	ret
	.p2align 4,,10
	.p2align 3
.L2:
	mov	BYTE PTR [rsi], 48
	mov	eax, 1
	ret
	.p2align 4,,10
	.p2align 3
.L11:
	ret
	.cfi_endproc
.LFE4:
	.size	atoi, .-atoi
	.p2align 4,,15
	.globl	_start
	.type	_start, @function
_start:
.LFB5:
	.cfi_startproc
	push	rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	mov	r10d, 1
	movabs	rsi, 9223372036854775807
	movabs	r11, -3689348814741910323
	sub	rsp, 16
	.cfi_def_cfa_offset 32
	lea	rdi, 8[rsp]
	lea	rbx, 27[rsp]
	mov	r9, rdi
	mov	r8, rdi
	sub	r10d, edi
	.p2align 4,,10
	.p2align 3
.L13:
	mov	rax, rsi
	lea	ecx, [r10+r8]
	add	r8, 1
	mul	r11
	shr	rdx, 3
	lea	rax, [rdx+rdx*4]
	add	rax, rax
	sub	rsi, rax
	add	esi, 48
	mov	BYTE PTR -1[r8], sil
	mov	rsi, rdx
	cmp	rbx, r8
	jne	.L13
	mov	esi, ecx
	sar	esi
	je	.L14
	movsx	rax, ecx
	lea	rdx, 1[rdi]
	sub	esi, 1
	add	rax, rdi
	add	rsi, rdx
	jmp	.L15
	.p2align 4,,10
	.p2align 3
.L22:
	add	rdx, 1
.L15:
	movzx	r8d, BYTE PTR [r9]
	movzx	r10d, BYTE PTR -1[rax]
	sub	rax, 1
	mov	BYTE PTR [r9], r10b
	mov	r9, rdx
	mov	BYTE PTR [rax], r8b
	cmp	rdx, rsi
	jne	.L22
.L14:
	mov	rdx, rdi
	mov	esi, 1
	mov	edi, 1
	xor	eax, eax
	call	syscall@PLT
	xor	esi, esi
	mov	edi, 60
	xor	eax, eax
	call	syscall@PLT
	add	rsp, 16
	.cfi_def_cfa_offset 16
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE5:
	.size	_start, .-_start
	.ident	"GCC: (Debian 8.3.0-6) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
