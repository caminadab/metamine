.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# B := [104, 111, 105, 46, 116, 120, 116, 0]
lea rax, -8[rsp]
mov -24[rsp], rax
movq -16[rsp], 8
mov eax, 0x2e696f68
mov -8[rsp], eax
mov eax, 0x00747874
mov -4[rsp], eax
lea rax, -24[rsp]
# C := 2
mov rax, 2
mov -32[rsp], rax 	# C
# C += 64
mov rax, -32[rsp]
mov rbx, 64
add rax, rbx
mov -32[rsp], rax 	# C
# A := syscall(2, B, C, 420)
mov rax, 2
mov rdi, -24[rsp]
mov rsi, -32[rsp]
mov rdx, 420
syscall
mov -40[rsp], rax
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

