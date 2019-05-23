.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# B := [104, 111, 105]
lea rax, -11[rsp]
mov -19[rsp], rax
movq -11[rsp], 3
movq rax, 0x696f68
mov -3[rsp], rax
lea rax, -19[rsp]
# A := 3
mov rax, 3
mov -32[rsp], rax 	# A
# A += B
mov rax, -32[rsp]
mov rbx, -19[rsp]
add rax, rbx
mov -32[rsp], rax 	# A
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

