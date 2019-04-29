.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
sub rsp, 64
lea r12, [rsp]
call vul
mov r13, rax
mov rax, 1
mov rdi, 1
mov rsi, r12
mov rdx, r13
syscall  # write
mov rax, r13
mov r14, rax
mov rax, 60
mov r15, rdi
mov rdi, 0
syscall  # exit
mov rax, r14
mov rdi, r15
ret

vul:
mov rbx, r13
mov r13, rax
mov rax, 72  # a 0
lea r13, [rdi+rdi]
movb [r13], al
mov rax, 60
mov r8, rdi
mov rdi, rdi
syscall  # exit
mov rdi, r8
mov r9, r14
mov r14, rax
mov rax, 105  # a 1
lea r14, [r8+r15]
movb [r14], al
mov rax, 2
ret


