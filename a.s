.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
mov rcx, -40[rsp]
mov rax, -32[rsp]
mov rdx, -24[rsp]
cmp rcx, 0
cmovg rax, rdx
mov -0[rsp], rax
mov rax, 1
mov -8[rsp], rax
mov rax, -8[rsp]
mov rbx, -0[rsp]
mul rbx
mov -8[rsp], rax
mov rax, 0
mov -16[rsp], rax
mov rax, -16[rsp]
mov rbx, -8[rsp]
add rax, rbx
mov -16[rsp], rax
mov rdi, rax
mov rax, 60
syscall
ret

p2:
mov rax, 3
mov -24[rsp], rax
lea rax, p1[rip]
jmp rax
p3:
mov rax, 2
mov -32[rsp], rax
lea rax, p1[rip]
jmp rax
_start:
mov rax, 0
mov -40[rsp], rax
mov rax, -40[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
