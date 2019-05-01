.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
sub rsp, 8
lea r12, [rsp]
mov rax, 72  # d 0
lea r13, [r12+0]
movb [r13], al
mov rax, 111  # d 1
lea r14, [r12+1]
movb [r14], al
mov rax, 105  # d 2
lea r15, [r12+2]
movb [r15], al
mov rax, 3
ret

mov rax, 75  # d n
lea rbx, [r12+n]
movb [rbx], al
mov rax, 1
mov rdi, 1
mov rsi, r12
mov rdx, 4
syscall  # write
mov r13, rax
mov rax, 60
mov r14, rdi
mov rdi, 0
syscall  # exit
mov rax, r13
mov rdi, r14

