.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
sub rsp, 20
lea r12, [rsp]
mov rdi, 123456789  # argument
mov rsi, r12  # argument
call atoi
mov r13, rax
mov rax, 1
mov rdi, 1
mov rsi, r12
mov rdx, r13
syscall

mov rax, r13
mov r14, rax
mov rax, 60
mov rdi, 0
syscall

mov rax, r14
atoi:
mov r15, r13
mov r13, 0
mov rbx, r14
mov r14, 0
cmp rdi, r14
jne lus
nul:
mov rdx, r15
mov r15, rax
mov rax, 48
lea r15, [rsi+0]
movb [r15], al
inc rdx
mov rax, rdx
ret
lus:
mov r8, rbx
mov rbx, 10
mov r9, rdx
mov rax, rdi
xor rdx, rdx
idivq rbx
mov rdi, rax
mov r10, rdx
mov rdx, 0
cmp rdi, rdx
je klaar
mov rax, rsi
mov rsi, 48
add rsi, r10
push r10
mov r10, rax
mov rax, rsi
lea rdi, [r10+r9]
movb [rdi], al
inc r9
jmp lus
klaar:
mov rax, r9
ret

