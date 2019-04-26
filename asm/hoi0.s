	.file	"hoi0.c"
	.intel_syntax noprefix
	.text
	.globl	getallen
	.data
	.align 32
	.type	getallen, @object
	.size	getallen, 256
getallen:
	.string	"hoi\n"
	.zero	251
	.text
	.globl	_start
	.type	_start, @function
_start:
.LFB0:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	mov	BYTE PTR getallen[rip], 72
	mov	ecx, 4
	lea	rdx, getallen[rip]
	mov	esi, 1
	mov	edi, 1
	mov	eax, 0
	call	syscall@PLT
	mov	esi, 0
	mov	edi, 60
	mov	eax, 0
	call	syscall@PLT
	nop
	pop	rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	_start, .-_start
	.ident	"GCC: (Debian 8.3.0-6) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
