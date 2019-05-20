.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
movq -38[rsp], 22
movq rax, 0x6f6c6c6168
mov -30[rsp], rax
movq rax, 0x726577206f
mov -26[rsp], rax
movq rax, 0x6a646c6572
mov -22[rsp], rax
movq rax, 0x617620656a
mov -18[rsp], rax
movq rax, 0x656d206e61
mov -14[rsp], rax
movq rax, 0x0a65
mov -10[rsp], rax
lea rax, -30[rsp]
mov rdi, 1
lea rsi, -30[rsp]
movq rdx, -8[rsi]
mov rax, 1
syscall
mov rdi, 0
mov rax, 60
syscall
ret

