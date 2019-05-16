	.file	"main.s"
	.intel_syntax noprefix
	.text
	.global	_start

_start:
	# rax (rdi, rsi, rdx, r10, r8, r9)

	# write(stdout, "hoi", 3)
	mov rax, 1
	mov rdi, 2
	lea rsi, hoi[rip]
	mov rdx, 3
	syscall

	call luaJIT_BC_ok@PLT

	# exit(0)
	mov rax, 60
	mov rdi, 0
	syscall

hoi: .ascii "hoi"
