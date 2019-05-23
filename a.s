.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
# A := B
mov rax, -36[rsp]
mov -8[rsp], rax 	# A
# stop
mov rdi, 1
mov rsi, -8[rsp]
movq rdx, [rsi]
add rsi, 8
mov rax, 1
syscall
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

p2:
# B := [71, 114, 111, 116, 101, 114, 32, 100, 97, 110, 33, 10]
lea rax, -28[rsp]
mov -36[rsp], rax
movq -28[rsp], 12
movq rax, 0x65746f7247
mov -20[rsp], rax
movq rax, 0x6164207265
mov -16[rsp], rax
movq rax, 0x0a216e61
mov -12[rsp], rax
lea rax, -36[rsp]
# ga p1
lea rax, p1[rip]
jmp rax
p3:
# B := [107, 108, 101, 105, 110, 101, 114, 10]
lea rax, -28[rsp]
mov -36[rsp], rax
movq -28[rsp], 8
movq rax, 0x6e69656c6b
mov -20[rsp], rax
movq rax, 0x0a72656e
mov -16[rsp], rax
lea rax, -36[rsp]
# ga p1
lea rax, p1[rip]
jmp rax
_start:
# C := 2 = 1
mov rax, 2
mov rbx, 1
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmove rax, rbx
mov -48[rsp], rax 	# C
# ga(C, p2, p3)
mov rax, -48[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
