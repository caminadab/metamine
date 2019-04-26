.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
	mov rax, 1
	mov rdi, 1
	lea rsi, .d0[rip]
	mov rdx, 4
	syscall
	mov rax, 60
	mov rdi, 0
	syscall
	ret


.d0:
	.byte 104,111,105,10

