.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# B := [104, 111, 105, 46, 116, 120, 116]
lea rax, -16[rsp]
mov -24[rsp], rax
movq -16[rsp], 7
mov eax, 0x2e696f68
mov -8[rsp], eax
mov eax, 0x747874
mov -4[rsp], eax
lea rax, -24[rsp]
# A := syscall(1, B, 0)
mov rax, 1
mov rsi, -24[rsp]
mov rdx, 0
syscall
# stop
mov rdi, 1
mov rsi, -32[rsp]
movq rdx, [rsi]
add rsi, 8
mov rax, 1
syscall
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

