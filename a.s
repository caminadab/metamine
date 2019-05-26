.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# D := [104, 111, 105]
lea rax, -1032[rsp]
mov -1048[rsp], rax
movq -1040[rsp], 3
mov eax, 0x696f68
mov -1032[rsp], eax
lea rax, -1048[rsp]
# E := [10]
lea rax, -2080[rsp]
mov -2096[rsp], rax
movq -2088[rsp], 1
mov eax, 0x0a
mov -2080[rsp], eax
lea rax, -2096[rsp]
# C := D
mov rax, -1048[rsp]
mov -2104[rsp], rax 	# C
# C ||= E
mov rax, -2104[rsp]
mov rcx, -2096[rsp]
mov rbx, -8[rax]
mov rdx, -8[rcx]
inc rbx
inc rdx
add rbx, rdx
dec rbx
dec rbx
mov -8[rax], rbx
sub rbx, rdx
dec rcx
add rax, rdx
add rax, rbx
add rcx, rdx
catA_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catA_eind
mov bl, [rcx]
mov [rax], bl
jmp catA_start
catA_eind:
# H := [104, 111, 105]
lea rax, -3136[rsp]
mov -3152[rsp], rax
movq -3144[rsp], 3
mov eax, 0x696f68
mov -3136[rsp], eax
lea rax, -3152[rsp]
# I := [10]
lea rax, -4184[rsp]
mov -4200[rsp], rax
movq -4192[rsp], 1
mov eax, 0x0a
mov -4184[rsp], eax
lea rax, -4200[rsp]
# G := H
mov rax, -3152[rsp]
mov -4208[rsp], rax 	# G
# G ||= I
mov rax, -4208[rsp]
mov rcx, -4200[rsp]
mov rbx, -8[rax]
mov rdx, -8[rcx]
inc rbx
inc rdx
add rbx, rdx
dec rbx
dec rbx
mov -8[rax], rbx
sub rbx, rdx
dec rcx
add rax, rdx
add rax, rbx
add rcx, rdx
catB_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catB_eind
mov bl, [rcx]
mov [rax], bl
jmp catB_start
catB_eind:
# F := # G
mov rbx, -4208[rsp]
mov rax, -8[rbx]
mov -4216[rsp], rax 	# F
# B := syscall(1, 1, C, F)
mov rax, 1
mov rdi, 1
mov rsi, -2104[rsp]
mov rdx, -4216[rsp]
syscall
mov -4224[rsp], rax
# A := 3 syscall B
mov rax, 3
mov rdi, -4224[rsp]
syscall
mov -4232[rsp], rax
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

