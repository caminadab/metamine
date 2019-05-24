.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
# D := E
mov rax, -48[rsp]
mov -8[rsp], rax 	# D
# B := C D
lea rbx, -56[rsp]
mov rcx, -8[rsp]
add rbx, rcx
movb al, [rbx]
mov -16[rsp], rax
# A := [65, B, 75, 10]
lea rax, -32[rsp]
mov -40[rsp], rax
movq -32[rsp], 4
mov eax, 0x0a4b0041
mov -24[rsp], eax
movb al, -16[rsp]
movb -23[rsp], al
lea rax, -40[rsp]
# stop
mov rdi, 1
mov rsi, -40[rsp]
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
# E := 0
mov rax, 0
mov -48[rsp], rax 	# E
# ga p1
lea rax, p1[rip]
jmp rax
p3:
# E := 2
mov rax, 2
mov -48[rsp], rax 	# E
# ga p1
lea rax, p1[rip]
jmp rax
_start:
# C := [104, 111, 105]
lea rax, -64[rsp]
mov -72[rsp], rax
movq -64[rsp], 3
mov eax, 0x696f68
mov -56[rsp], eax
lea rax, -72[rsp]
# F := 2 < 1
mov rax, 2
mov rbx, 1
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovl rax, rbx
mov -80[rsp], rax 	# F
# ga(F, p2, p3)
mov rax, -80[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
