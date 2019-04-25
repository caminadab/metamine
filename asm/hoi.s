	.intel_syntax noprefix
	.text
	.global	_start

.section .text

_start:
	mov rax, 1
	mov rdi, 1
	lea rsi, .var[rip]
	mov rdx, 4
	syscall
	mov rax, 60
	mov rdi, 0
	syscall
	ret

.var:
	.string	"hoi\n"
