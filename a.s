.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
mov r12, 0
mov r13, 30
lus:
add r12, 1
add r12, 1
cmp r12, r13
jg klaar
mov rax, 1
mov rdi, 0
lea rsi, a[rip]
mov rdx, 4
syscall

jmp lus
klaar:
mov r14, rax
mov rax, 60
mov rdi, 0
syscall

mov rax, r14
a: .byte 104,111,105,10
