.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
# A := B
mov rax, -1064[rsp]
mov -8[rsp], rax 	# A
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

p2:
# C := [104, 111, 105]
lea rax, -1040[rsp]
mov -1056[rsp], rax
movq -1048[rsp], 3
mov eax, 0x696f68
mov -1040[rsp], eax
lea rax, -1056[rsp]
# B := C 4
lea rbx, -1040[rsp]
mov rcx, 4
add rbx, rcx
movb al, [rbx]
mov -1064[rsp], rax
# ga p1
lea rax, p1[rip]
jmp rax
p3:
# ga p1
lea rax, p1[rip]
jmp rax
_start:
# D := ja
mov rax, 1
mov -1072[rsp], rax 	# D
# ga(D, p2, p3)
mov rax, -1072[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
