.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
mov r12, 0
mov r13, 1
mov r14, 2
mov r15, 3
mov r10, 4
mov r9, 5
mov r8, 6
mov rcx, 7
mov rdx, 8
mov rsi, 9
mov rdi, 10
mov rax, 1
push rdi
mov rdi, 1
push r10
lea rsi, data[rip]
mov r10, rdx  # maak ruimte
mov rdx, 4
syscall  # write
push rsi
mov rax, 60
mov rsi, rdi  # maak ruimte
mov rdi, 0
syscall  # exit
data: .byte 72,111,105,10
