.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
mov rdi, 20000000
call malloc

mov rdi, 20000000
call malloc

movq [rax], 3
movq [rax+10000], 2

mov rdi, rax
call free

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

