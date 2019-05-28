.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
# E := F
mov rax, -1072[rsp]
mov -8[rsp], rax 	# E
# M := 1
mov rax, 1
mov -16[rsp], rax 	# M
# M /= 3
mov rax, -16[rsp]
mov rbx, 3
cdq
idivq rbx
mov -16[rsp], rax 	# M
# L := M > 0
mov rax, -16[rsp]
mov rbx, 0
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovg rax, rbx
mov -24[rsp], rax 	# L
# ga(L, p5, p6)
mov rax, -24[rsp]
lea rbx, p5[rip]
lea rdx, p6[rip]
cmp rax, 0
jnz p5
jmp rdx
p2:
# F := [103, 111, 101, 100, 33]
lea rax, -1056[rsp]
mov -1072[rsp], rax
movq -1064[rsp], 5
mov eax, 0x64656f67
mov -1056[rsp], eax
mov eax, 0x21
mov -1052[rsp], eax
lea rax, -1072[rsp]
# ga p1
lea rax, p1[rip]
jmp rax
p3:
# F := [102, 111, 117, 116, 33]
lea rax, -1056[rsp]
mov -1072[rsp], rax
movq -1064[rsp], 5
mov eax, 0x74756f66
mov -1056[rsp], eax
mov eax, 0x21
mov -1052[rsp], eax
lea rax, -1072[rsp]
# ga p1
lea rax, p1[rip]
jmp rax
p4:
# J := K
mov rax, -2168[rsp]
mov -1080[rsp], rax 	# J
# I := # J
mov rbx, -1080[rsp]
mov rax, -8[rbx]
mov -1088[rsp], rax 	# I
# D := syscall(1, 1, E, I)
mov rax, 1
mov rdi, 1
mov rsi, -8[rsp]
mov rdx, -1088[rsp]
syscall
mov -1096[rsp], rax
# C := D
mov rax, -1096[rsp]
mov -1104[rsp], rax 	# C
# C *= 0
mov rax, -1104[rsp]
mov rbx, 0
mul rbx
mov -1104[rsp], rax 	# C
# B := C
mov rax, -1104[rsp]
mov -1112[rsp], rax 	# B
# B += 1
mov rax, -1112[rsp]
mov rbx, 1
add rax, rbx
mov -1112[rsp], rax 	# B
# A := 3 syscall B
mov rax, 3
mov rdi, -1112[rsp]
syscall
mov -1120[rsp], rax
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

p5:
# K := [103, 111, 101, 100, 33]
lea rax, -2152[rsp]
mov -2168[rsp], rax
movq -2160[rsp], 5
mov eax, 0x64656f67
mov -2152[rsp], eax
mov eax, 0x21
mov -2148[rsp], eax
lea rax, -2168[rsp]
# ga p4
lea rax, p4[rip]
jmp rax
p6:
# K := [102, 111, 117, 116, 33]
lea rax, -2152[rsp]
mov -2168[rsp], rax
movq -2160[rsp], 5
mov eax, 0x74756f66
mov -2152[rsp], eax
mov eax, 0x21
mov -2148[rsp], eax
lea rax, -2168[rsp]
# ga p4
lea rax, p4[rip]
jmp rax
_start:
# H := 1
mov rax, 1
mov -2176[rsp], rax 	# H
# H /= 3
mov rax, -2176[rsp]
mov rbx, 3
cdq
idivq rbx
mov -2176[rsp], rax 	# H
# G := H > 0
mov rax, -2176[rsp]
mov rbx, 0
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovg rax, rbx
mov -2184[rsp], rax 	# G
# ga(G, p2, p3)
mov rax, -2184[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
