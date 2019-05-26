.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# G := [104, 111, 105]
lea rax, -1032[rsp]
mov -1048[rsp], rax
movq -1040[rsp], 3
mov eax, 0x696f68
mov -1032[rsp], eax
lea rax, -1048[rsp]
# H := [98]
lea rax, -2080[rsp]
mov -2096[rsp], rax
movq -2088[rsp], 1
mov eax, 0x62
mov -2080[rsp], eax
lea rax, -2096[rsp]
# F := G
mov rax, -1048[rsp]
mov -2104[rsp], rax 	# F
# F ||= H
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
# I := [99]
lea rax, -3136[rsp]
mov -3152[rsp], rax
movq -3144[rsp], 1
mov eax, 0x63
mov -3136[rsp], eax
lea rax, -3152[rsp]
# E := F
mov rax, -2104[rsp]
mov -3160[rsp], rax 	# E
# E ||= I
mov rax, -3160[rsp]
mov rcx, -3152[rsp]
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
# J := []
lea rax, -4184[rsp]
mov -4200[rsp], rax
movq -4192[rsp], 0
lea rax, -4200[rsp]
# D := E
mov rax, -3160[rsp]
mov -4208[rsp], rax 	# D
# D ||= J
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
# K := [106, 105, 112, 112, 105, 101, 33]
lea rax, -5240[rsp]
mov -5256[rsp], rax
movq -5248[rsp], 7
mov eax, 0x7070696a
mov -5240[rsp], eax
mov eax, 0x216569
mov -5236[rsp], eax
lea rax, -5256[rsp]
# C := D
mov rax, -4208[rsp]
mov -5264[rsp], rax 	# C
# C ||= K
mov rax, -5264[rsp]
mov rcx, -5256[rsp]
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
# Q := [104, 111, 105]
lea rax, -6296[rsp]
mov -6312[rsp], rax
movq -6304[rsp], 3
mov eax, 0x696f68
mov -6296[rsp], eax
lea rax, -6312[rsp]
# R := [98]
lea rax, -7344[rsp]
mov -7360[rsp], rax
movq -7352[rsp], 1
mov eax, 0x62
mov -7344[rsp], eax
lea rax, -7360[rsp]
# P := Q
mov rax, -6312[rsp]
mov -7368[rsp], rax 	# P
# P ||= R
mov rax, -7368[rsp]
mov rcx, -7360[rsp]
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
catE_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catE_eind
mov bl, [rcx]
mov [rax], bl
jmp catE_start
catE_eind:
# S := [99]
lea rax, -8400[rsp]
mov -8416[rsp], rax
movq -8408[rsp], 1
mov eax, 0x63
mov -8400[rsp], eax
lea rax, -8416[rsp]
# O := P
mov rax, -7368[rsp]
mov -8424[rsp], rax 	# O
# O ||= S
mov rax, -8424[rsp]
mov rcx, -8416[rsp]
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
catF_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catF_eind
mov bl, [rcx]
mov [rax], bl
jmp catF_start
catF_eind:
# T := []
lea rax, -9448[rsp]
mov -9464[rsp], rax
movq -9456[rsp], 0
lea rax, -9464[rsp]
# N := O
mov rax, -8424[rsp]
mov -9472[rsp], rax 	# N
# N ||= T
mov rax, -9472[rsp]
mov rcx, -9464[rsp]
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
catG_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catG_eind
mov bl, [rcx]
mov [rax], bl
jmp catG_start
catG_eind:
# U := [106, 105, 112, 112, 105, 101, 33]
lea rax, -10504[rsp]
mov -10520[rsp], rax
movq -10512[rsp], 7
mov eax, 0x7070696a
mov -10504[rsp], eax
mov eax, 0x216569
mov -10500[rsp], eax
lea rax, -10520[rsp]
# M := N
mov rax, -9472[rsp]
mov -10528[rsp], rax 	# M
# M ||= U
mov rax, -10528[rsp]
mov rcx, -10520[rsp]
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
catH_start:
dec rdx
dec rcx
dec rax
cmp rdx, 0
je catH_eind
mov bl, [rcx]
mov [rax], bl
jmp catH_start
catH_eind:
# L := # M
mov rbx, -10528[rsp]
mov rax, -8[rbx]
mov -10536[rsp], rax 	# L
# B := syscall(1, 1, C, L)
mov rax, 1
mov rdi, 1
mov rsi, -5264[rsp]
mov rdx, -10536[rsp]
syscall
mov -10544[rsp], rax
# A := 3 syscall B
mov rax, 3
mov rdi, -10544[rsp]
syscall
mov -10552[rsp], rax
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

