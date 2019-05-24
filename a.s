.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# B := 111
mov rax, 111
mov -8[rsp], rax 	# B
# B += 1
mov rax, -8[rsp]
mov rbx, 1
add rax, rbx
mov -8[rsp], rax 	# B
# A := [104, B, 105, 10]
lea rax, -24[rsp]
mov -32[rsp], rax
movq -24[rsp], 4
mov eax, 0x0a690068
mov -16[rsp], eax
movb al, -8[rsp]
movb -15[rsp], al
lea rax, -32[rsp]
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

