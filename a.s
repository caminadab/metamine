.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
# A := B
mov rax, -28[rsp]
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
# B := [49, 48, 50, 106]
lea rax, -20[rsp]
mov -28[rsp], rax
movq -20[rsp], 4
movq rax, 0x6a323031
mov -12[rsp], rax
lea rax, -28[rsp]
# ga p1
lea rax, p1[rip]
jmp rax
p3:
# B := [88, 88]
lea rax, -20[rsp]
mov -28[rsp], rax
movq -20[rsp], 2
movq rax, 0x5858
mov -12[rsp], rax
lea rax, -28[rsp]
# ga p1
lea rax, p1[rip]
jmp rax
_start:
# C := 2 < 1
mov rax, 2
mov rbx, 1
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovl rax, rbx
mov -40[rsp], rax 	# C
# ga(C, p2, p3)
mov rax, -40[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
