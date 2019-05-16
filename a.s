.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
mov rax, 3
mov [rsp+8*0], rax
mov rax, [rsp+8*0]
mov rbx, 1
add rax, rbx
mov [rsp+8*0], rax
mov rax, [rsp+8*0]
mov [rsp+8*1], rax
mov rax, [rsp+8*1]
mov rbx, 1
add rax, rbx
mov [rsp+8*1], rax
mov rdi, rax
mov rax, 60
syscall
ret
