.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
movq -50[rsp], 34
movq rax, 0x6420696f68
mov -42[rsp], rax
movq rax, 0x67206e6164
mov -38[rsp], rax
movq rax, 0x2074616167
mov -34[rsp], rax
movq rax, 0x2074656820
mov -30[rsp], rax
movq rax, 0x68636f7420
mov -26[rsp], rax
movq rax, 0x656f672068
mov -22[rsp], rax
movq rax, 0x6577206465
mov -18[rsp], rax
movq rax, 0x646c657265
mov -14[rsp], rax
movq rax, 0x0a64
mov -10[rsp], rax
lea rax, -42[rsp]
mov rdi, 1
lea rsi, -42[rsp]
movq rdx, -8[rsi]
mov rax, 1
syscall
mov rdi, 0
mov rax, 60
syscall
ret

