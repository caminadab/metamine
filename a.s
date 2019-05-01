.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
sub rsp, 8
lea r12, [rsp]
mov rax, 8
ret

mov rdi, r12  # argument
lea rsi, d[rip]  # argument
lea rdx, e[rip]  # argument
call memcpy
mov rdi, r12  # argument
call vul
mov r13, rax
mov rax, 1
mov rdi, 1
mov rsi, r13
mov rdx, 3
syscall  # write
mov rax, r13
mov r14, rax
mov rax, 60
mov r15, rdi
mov rdi, 0
syscall  # exit
mov rax, r14
mov rdi, r15
vul:
mov rbx, r13
mov r13, rax
mov rax, 72  # a 0
lea r13, [rdi+0]
movb [r13], al
mov rax, rdi
ret

d: .byte 104,111,105
