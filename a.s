.intel_syntax noprefix
.global _start

_start:
mov rax, 3
mov [rbp+8*0], rax
mov rax, 2
mov [rbp+8*1], rax
mov rax, 1
mov [rbp+8*2], rax
mov rax, [rbp+8*2]
mov [rbp+8*3], rax
mov rax, [rbp+8*3]
mov rbx, 8
add rax, rbx
mov [rbp+8*3], rax
mov rax, 8
mov [rbp+8*4], rax
mov rax, [rbp+8*1]
mov [rbp+8*5], rax
mov rax, [rbp+8*5]
mov [rbp+8*6], rax
mov rax, [rbp+8*6]
mov [rbp+8*7], rax
mov rax, [rbp+8*7]
mov [rbp+8*8], rax
mov rax, [rbp+8*8]
mov [rbp+8*9], rax
