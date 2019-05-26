.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# E := []
lea rax, -1024[rsp]
mov -1040[rsp], rax
movq -1032[rsp], 0
lea rax, -1040[rsp]
# F := [79, 75, 69, 69, 33]
lea rax, -2072[rsp]
mov -2088[rsp], rax
movq -2080[rsp], 5
mov eax, 0x45454b4f
mov -2072[rsp], eax
mov eax, 0x21
mov -2068[rsp], eax
lea rax, -2088[rsp]
# D := E
mov rax, -1040[rsp]
mov -2096[rsp], rax 	# D
# D ||= F
mov rax, -2096[rsp]
mov rcx, -2088[rsp]
mov rbx, -8[rax]
mov rdx, -8[rcx]
inc rbx
inc rdx
add rbx, rdx
inc rbx
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
# G := [10]
lea rax, -3128[rsp]
mov -3144[rsp], rax
movq -3136[rsp], 1
mov eax, 0x0a
mov -3128[rsp], eax
lea rax, -3144[rsp]
# C := D
mov rax, -2096[rsp]
mov -3152[rsp], rax 	# C
# C ||= G
mov rax, -3152[rsp]
mov rcx, -3144[rsp]
mov rbx, -8[rax]
mov rdx, -8[rcx]
inc rbx
inc rdx
add rbx, rdx
inc rbx
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
# K := []
lea rax, -4176[rsp]
mov -4192[rsp], rax
movq -4184[rsp], 0
lea rax, -4192[rsp]
# L := [79, 75, 69, 69, 33]
lea rax, -5224[rsp]
mov -5240[rsp], rax
movq -5232[rsp], 5
mov eax, 0x45454b4f
mov -5224[rsp], eax
mov eax, 0x21
mov -5220[rsp], eax
lea rax, -5240[rsp]
# J := K
mov rax, -4192[rsp]
mov -5248[rsp], rax 	# J
# J ||= L
mov rax, -5248[rsp]
mov rcx, -5240[rsp]
mov rbx, -8[rax]
mov rdx, -8[rcx]
inc rbx
inc rdx
add rbx, rdx
inc rbx
mov -8[rax], rbx
sub rbx, rdx
dec rcx
add rax, rdx
add rax, rbx
add rcx, rdx
catC_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catC_eind
mov bl, [rcx]
mov [rax], bl
jmp catC_start
catC_eind:
# M := [10]
lea rax, -6280[rsp]
mov -6296[rsp], rax
movq -6288[rsp], 1
mov eax, 0x0a
mov -6280[rsp], eax
lea rax, -6296[rsp]
# I := J
mov rax, -5248[rsp]
mov -6304[rsp], rax 	# I
# I ||= M
mov rax, -6304[rsp]
mov rcx, -6296[rsp]
mov rbx, -8[rax]
mov rdx, -8[rcx]
inc rbx
inc rdx
add rbx, rdx
inc rbx
mov -8[rax], rbx
sub rbx, rdx
dec rcx
add rax, rdx
add rax, rbx
add rcx, rdx
catD_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catD_eind
mov bl, [rcx]
mov [rax], bl
jmp catD_start
catD_eind:
# H := # I
mov rbx, -6304[rsp]
mov rax, -8[rbx]
mov -6312[rsp], rax 	# H
# B := syscall(1, 1, C, H)
mov rax, 1
mov rdi, 1
mov rsi, -3152[rsp]
mov rdx, -6312[rsp]
syscall
mov -6320[rsp], rax
# A := 3 syscall B
mov rax, 3
mov rdi, -6320[rsp]
syscall
mov -6328[rsp], rax
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

