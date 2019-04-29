	.file	"fib.c"
	.intel_syntax noprefix
	.text
	.globl	fib
	.type	fib, @function
fib:
.LFB0:
	push	rbp
	mov	rbp, rsp
	push	rbx
	sub	rsp, 24
	mov	QWORD PTR -24[rbp], rdi
	cmp	QWORD PTR -24[rbp], 0
	je	.L2
	cmp	QWORD PTR -24[rbp], 1
	jne	.L3
.L2:
	mov	rax, QWORD PTR -24[rbp]
	jmp	.L4
.L3:
	mov	rax, QWORD PTR -24[rbp]
	sub	rax, 1
	mov	rdi, rax
	call	fib
	mov	rbx, rax
	mov	rax, QWORD PTR -24[rbp]
	sub	rax, 2
	mov	rdi, rax
	call	fib
	add	rax, rbx
.L4:
	add	rsp, 24
	pop	rbx
	pop	rbp
	ret
.LFE0:
	.size	fib, .-fib
	.section	.rodata
.LC0:
	.string	"fib(10) = %d\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB1:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16
	mov	QWORD PTR -8[rbp], 10
	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax
	call	fib
	mov	QWORD PTR -16[rbp], rax
	mov	rax, QWORD PTR -16[rbp]
	mov	rsi, rax
	lea	rdi, .LC0[rip]
	mov	eax, 0
	call	printf@PLT
	mov	eax, 0
	leave
	ret
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Debian 8.3.0-6) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
