.intel_syntax noprefix
.text
.global	_start

.section .text

movq -0[rsp], 3
lea rax, -8[rsp]
movq -8[rsp], 2
lea rax, -16[rsp]
mov -64[rsp], rax
lea r12, -8[rsp]
mov rcx, -8[rsp]
mov r13, r12
dec rcx
lea rbx, -24[rsp]
mov rax, -16[rsp]
mov r14, rbx
add r13, rax
add rbx, rax
catlusA:
mov rax, [rbx]
mov [r12], rax
dec rcx
dec r12
cmp rcx, -1
jne catlusA
mov [r14], rbx
mov rax, r14
mov -128[rsp], rax
mov rdi, 1
lea rsi, -8[r14]
movq rdx, [r14]
mov rax, 1
syscall
mov rdi, 0
mov rax, 60
syscall
ret

