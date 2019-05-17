.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
mov rax, 2
mov -0[rsp], rax
mov rax, -0[rsp]
mov rbx, 3
add rax, rbx
mov -0[rsp], rax
mov rdi, rax
mov rax, 60
syscall
ret

