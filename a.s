.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
# J := 100
mov rax, 100
mov -8[rsp], rax 	# J
# wortel= J
fildd -8[rsp]
fsqrt
fistpd -8[rsp]
# I := J
mov rax, -8[rsp]
mov -16[rsp], rax 	# I
# I /= 100000000
mov rax, -16[rsp]
mov rbx, 100000000
cdq
idivq rbx
mov -16[rsp], rax 	# I
# H := I
mov rax, -16[rsp]
mov -24[rsp], rax 	# H
# H mod= 10
mov rax, -24[rsp]
mov rbx, 10
cdq
idivq rbx
mov -24[rsp], rdx 	# H
# G := 48
mov rax, 48
mov -32[rsp], rax 	# G
# G += H
mov rax, -32[rsp]
mov rbx, -24[rsp]
add rax, rbx
mov -32[rsp], rax 	# G
# N := 100
mov rax, 100
mov -40[rsp], rax 	# N
# wortel= N
fildd -40[rsp]
fsqrt
fistpd -40[rsp]
# M := N
mov rax, -40[rsp]
mov -48[rsp], rax 	# M
# M /= 10000000
mov rax, -48[rsp]
mov rbx, 10000000
cdq
idivq rbx
mov -48[rsp], rax 	# M
# L := M
mov rax, -48[rsp]
mov -56[rsp], rax 	# L
# L mod= 10
mov rax, -56[rsp]
mov rbx, 10
cdq
idivq rbx
mov -56[rsp], rdx 	# L
# K := 48
mov rax, 48
mov -64[rsp], rax 	# K
# K += L
mov rax, -64[rsp]
mov rbx, -56[rsp]
add rax, rbx
mov -64[rsp], rax 	# K
# R := 100
mov rax, 100
mov -72[rsp], rax 	# R
# wortel= R
fildd -72[rsp]
fsqrt
fistpd -72[rsp]
# Q := R
mov rax, -72[rsp]
mov -80[rsp], rax 	# Q
# Q /= 1000000
mov rax, -80[rsp]
mov rbx, 1000000
cdq
idivq rbx
mov -80[rsp], rax 	# Q
# P := Q
mov rax, -80[rsp]
mov -88[rsp], rax 	# P
# P mod= 10
mov rax, -88[rsp]
mov rbx, 10
cdq
idivq rbx
mov -88[rsp], rdx 	# P
# O := 48
mov rax, 48
mov -96[rsp], rax 	# O
# O += P
mov rax, -96[rsp]
mov rbx, -88[rsp]
add rax, rbx
mov -96[rsp], rax 	# O
# V := 100
mov rax, 100
mov -104[rsp], rax 	# V
# wortel= V
fildd -104[rsp]
fsqrt
fistpd -104[rsp]
# U := V
mov rax, -104[rsp]
mov -112[rsp], rax 	# U
# U /= 100000
mov rax, -112[rsp]
mov rbx, 100000
cdq
idivq rbx
mov -112[rsp], rax 	# U
# T := U
mov rax, -112[rsp]
mov -120[rsp], rax 	# T
# T mod= 10
mov rax, -120[rsp]
mov rbx, 10
cdq
idivq rbx
mov -120[rsp], rdx 	# T
# S := 48
mov rax, 48
mov -128[rsp], rax 	# S
# S += T
mov rax, -128[rsp]
mov rbx, -120[rsp]
add rax, rbx
mov -128[rsp], rax 	# S
# Z := 100
mov rax, 100
mov -136[rsp], rax 	# Z
# wortel= Z
fildd -136[rsp]
fsqrt
fistpd -136[rsp]
# Y := Z
mov rax, -136[rsp]
mov -144[rsp], rax 	# Y
# Y /= 10000
mov rax, -144[rsp]
mov rbx, 10000
cdq
idivq rbx
mov -144[rsp], rax 	# Y
# X := Y
mov rax, -144[rsp]
mov -152[rsp], rax 	# X
# X mod= 10
mov rax, -152[rsp]
mov rbx, 10
cdq
idivq rbx
mov -152[rsp], rdx 	# X
# W := 48
mov rax, 48
mov -160[rsp], rax 	# W
# W += X
mov rax, -160[rsp]
mov rbx, -152[rsp]
add rax, rbx
mov -160[rsp], rax 	# W
# DB := 100
mov rax, 100
mov -168[rsp], rax 	# DB
# wortel= DB
fildd -168[rsp]
fsqrt
fistpd -168[rsp]
# CB := DB
mov rax, -168[rsp]
mov -176[rsp], rax 	# CB
# CB /= 1000
mov rax, -176[rsp]
mov rbx, 1000
cdq
idivq rbx
mov -176[rsp], rax 	# CB
# BB := CB
mov rax, -176[rsp]
mov -184[rsp], rax 	# BB
# BB mod= 10
mov rax, -184[rsp]
mov rbx, 10
cdq
idivq rbx
mov -184[rsp], rdx 	# BB
# AB := 48
mov rax, 48
mov -192[rsp], rax 	# AB
# AB += BB
mov rax, -192[rsp]
mov rbx, -184[rsp]
add rax, rbx
mov -192[rsp], rax 	# AB
# HB := 100
mov rax, 100
mov -200[rsp], rax 	# HB
# wortel= HB
fildd -200[rsp]
fsqrt
fistpd -200[rsp]
# GB := HB
mov rax, -200[rsp]
mov -208[rsp], rax 	# GB
# GB /= 100
mov rax, -208[rsp]
mov rbx, 100
cdq
idivq rbx
mov -208[rsp], rax 	# GB
# FB := GB
mov rax, -208[rsp]
mov -216[rsp], rax 	# FB
# FB mod= 10
mov rax, -216[rsp]
mov rbx, 10
cdq
idivq rbx
mov -216[rsp], rdx 	# FB
# EB := 48
mov rax, 48
mov -224[rsp], rax 	# EB
# EB += FB
mov rax, -224[rsp]
mov rbx, -216[rsp]
add rax, rbx
mov -224[rsp], rax 	# EB
# LB := 100
mov rax, 100
mov -232[rsp], rax 	# LB
# wortel= LB
fildd -232[rsp]
fsqrt
fistpd -232[rsp]
# KB := LB
mov rax, -232[rsp]
mov -240[rsp], rax 	# KB
# KB /= 10
mov rax, -240[rsp]
mov rbx, 10
cdq
idivq rbx
mov -240[rsp], rax 	# KB
# JB := KB
mov rax, -240[rsp]
mov -248[rsp], rax 	# JB
# JB mod= 10
mov rax, -248[rsp]
mov rbx, 10
cdq
idivq rbx
mov -248[rsp], rdx 	# JB
# IB := 48
mov rax, 48
mov -256[rsp], rax 	# IB
# IB += JB
mov rax, -256[rsp]
mov rbx, -248[rsp]
add rax, rbx
mov -256[rsp], rax 	# IB
# PB := 100
mov rax, 100
mov -264[rsp], rax 	# PB
# wortel= PB
fildd -264[rsp]
fsqrt
fistpd -264[rsp]
# OB := PB
mov rax, -264[rsp]
mov -272[rsp], rax 	# OB
# OB /= 1
mov rax, -272[rsp]
mov rbx, 1
cdq
idivq rbx
mov -272[rsp], rax 	# OB
# NB := OB
mov rax, -272[rsp]
mov -280[rsp], rax 	# NB
# NB mod= 10
mov rax, -280[rsp]
mov rbx, 10
cdq
idivq rbx
mov -280[rsp], rdx 	# NB
# MB := 48
mov rax, 48
mov -288[rsp], rax 	# MB
# MB += NB
mov rax, -288[rsp]
mov rbx, -280[rsp]
add rax, rbx
mov -288[rsp], rax 	# MB
# F := [G, K, O, S, W, AB, EB, IB, MB]
lea rax, -1328[rsp]
mov -1344[rsp], rax
movq -1336[rsp], 9
mov eax, 0x00000000
mov -1328[rsp], eax
movb al, -128[rsp]
movb -1325[rsp], al
movb al, -96[rsp]
movb -1326[rsp], al
movb al, -64[rsp]
movb -1327[rsp], al
movb al, -32[rsp]
movb -1328[rsp], al
mov eax, 0x00000000
mov -1324[rsp], eax
movb al, -256[rsp]
movb -1321[rsp], al
movb al, -224[rsp]
movb -1322[rsp], al
movb al, -192[rsp]
movb -1323[rsp], al
movb al, -160[rsp]
movb -1324[rsp], al
mov eax, 0x00
mov -1320[rsp], eax
movb al, -288[rsp]
movb -1320[rsp], al
lea rax, -1344[rsp]
# QB := [32, 72, 65, 76, 76, 79, 32, 80, 82, 65, 83, 65, 84, 72, 33, 33, 33, 10]
lea rax, -2392[rsp]
mov -2408[rsp], rax
movq -2400[rsp], 18
mov eax, 0x4c414820
mov -2392[rsp], eax
mov eax, 0x50204f4c
mov -2388[rsp], eax
mov eax, 0x41534152
mov -2384[rsp], eax
mov eax, 0x21214854
mov -2380[rsp], eax
mov eax, 0x0a21
mov -2376[rsp], eax
lea rax, -2408[rsp]
# E := F
mov rax, -1344[rsp]
mov -2416[rsp], rax 	# E
# E ||= QB
mov rax, -2416[rsp]
mov rcx, -2408[rsp]
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
# XB := 100
mov rax, 100
mov -2424[rsp], rax 	# XB
# wortel= XB
fildd -2424[rsp]
fsqrt
fistpd -2424[rsp]
# WB := XB
mov rax, -2424[rsp]
mov -2432[rsp], rax 	# WB
# WB /= 100000000
mov rax, -2432[rsp]
mov rbx, 100000000
cdq
idivq rbx
mov -2432[rsp], rax 	# WB
# VB := WB
mov rax, -2432[rsp]
mov -2440[rsp], rax 	# VB
# VB mod= 10
mov rax, -2440[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2440[rsp], rdx 	# VB
# UB := 48
mov rax, 48
mov -2448[rsp], rax 	# UB
# UB += VB
mov rax, -2448[rsp]
mov rbx, -2440[rsp]
add rax, rbx
mov -2448[rsp], rax 	# UB
# BC := 100
mov rax, 100
mov -2456[rsp], rax 	# BC
# wortel= BC
fildd -2456[rsp]
fsqrt
fistpd -2456[rsp]
# AC := BC
mov rax, -2456[rsp]
mov -2464[rsp], rax 	# AC
# AC /= 10000000
mov rax, -2464[rsp]
mov rbx, 10000000
cdq
idivq rbx
mov -2464[rsp], rax 	# AC
# ZB := AC
mov rax, -2464[rsp]
mov -2472[rsp], rax 	# ZB
# ZB mod= 10
mov rax, -2472[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2472[rsp], rdx 	# ZB
# YB := 48
mov rax, 48
mov -2480[rsp], rax 	# YB
# YB += ZB
mov rax, -2480[rsp]
mov rbx, -2472[rsp]
add rax, rbx
mov -2480[rsp], rax 	# YB
# FC := 100
mov rax, 100
mov -2488[rsp], rax 	# FC
# wortel= FC
fildd -2488[rsp]
fsqrt
fistpd -2488[rsp]
# EC := FC
mov rax, -2488[rsp]
mov -2496[rsp], rax 	# EC
# EC /= 1000000
mov rax, -2496[rsp]
mov rbx, 1000000
cdq
idivq rbx
mov -2496[rsp], rax 	# EC
# DC := EC
mov rax, -2496[rsp]
mov -2504[rsp], rax 	# DC
# DC mod= 10
mov rax, -2504[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2504[rsp], rdx 	# DC
# CC := 48
mov rax, 48
mov -2512[rsp], rax 	# CC
# CC += DC
mov rax, -2512[rsp]
mov rbx, -2504[rsp]
add rax, rbx
mov -2512[rsp], rax 	# CC
# JC := 100
mov rax, 100
mov -2520[rsp], rax 	# JC
# wortel= JC
fildd -2520[rsp]
fsqrt
fistpd -2520[rsp]
# IC := JC
mov rax, -2520[rsp]
mov -2528[rsp], rax 	# IC
# IC /= 100000
mov rax, -2528[rsp]
mov rbx, 100000
cdq
idivq rbx
mov -2528[rsp], rax 	# IC
# HC := IC
mov rax, -2528[rsp]
mov -2536[rsp], rax 	# HC
# HC mod= 10
mov rax, -2536[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2536[rsp], rdx 	# HC
# GC := 48
mov rax, 48
mov -2544[rsp], rax 	# GC
# GC += HC
mov rax, -2544[rsp]
mov rbx, -2536[rsp]
add rax, rbx
mov -2544[rsp], rax 	# GC
# NC := 100
mov rax, 100
mov -2552[rsp], rax 	# NC
# wortel= NC
fildd -2552[rsp]
fsqrt
fistpd -2552[rsp]
# MC := NC
mov rax, -2552[rsp]
mov -2560[rsp], rax 	# MC
# MC /= 10000
mov rax, -2560[rsp]
mov rbx, 10000
cdq
idivq rbx
mov -2560[rsp], rax 	# MC
# LC := MC
mov rax, -2560[rsp]
mov -2568[rsp], rax 	# LC
# LC mod= 10
mov rax, -2568[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2568[rsp], rdx 	# LC
# KC := 48
mov rax, 48
mov -2576[rsp], rax 	# KC
# KC += LC
mov rax, -2576[rsp]
mov rbx, -2568[rsp]
add rax, rbx
mov -2576[rsp], rax 	# KC
# RC := 100
mov rax, 100
mov -2584[rsp], rax 	# RC
# wortel= RC
fildd -2584[rsp]
fsqrt
fistpd -2584[rsp]
# QC := RC
mov rax, -2584[rsp]
mov -2592[rsp], rax 	# QC
# QC /= 1000
mov rax, -2592[rsp]
mov rbx, 1000
cdq
idivq rbx
mov -2592[rsp], rax 	# QC
# PC := QC
mov rax, -2592[rsp]
mov -2600[rsp], rax 	# PC
# PC mod= 10
mov rax, -2600[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2600[rsp], rdx 	# PC
# OC := 48
mov rax, 48
mov -2608[rsp], rax 	# OC
# OC += PC
mov rax, -2608[rsp]
mov rbx, -2600[rsp]
add rax, rbx
mov -2608[rsp], rax 	# OC
# VC := 100
mov rax, 100
mov -2616[rsp], rax 	# VC
# wortel= VC
fildd -2616[rsp]
fsqrt
fistpd -2616[rsp]
# UC := VC
mov rax, -2616[rsp]
mov -2624[rsp], rax 	# UC
# UC /= 100
mov rax, -2624[rsp]
mov rbx, 100
cdq
idivq rbx
mov -2624[rsp], rax 	# UC
# TC := UC
mov rax, -2624[rsp]
mov -2632[rsp], rax 	# TC
# TC mod= 10
mov rax, -2632[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2632[rsp], rdx 	# TC
# SC := 48
mov rax, 48
mov -2640[rsp], rax 	# SC
# SC += TC
mov rax, -2640[rsp]
mov rbx, -2632[rsp]
add rax, rbx
mov -2640[rsp], rax 	# SC
# ZC := 100
mov rax, 100
mov -2648[rsp], rax 	# ZC
# wortel= ZC
fildd -2648[rsp]
fsqrt
fistpd -2648[rsp]
# YC := ZC
mov rax, -2648[rsp]
mov -2656[rsp], rax 	# YC
# YC /= 10
mov rax, -2656[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2656[rsp], rax 	# YC
# XC := YC
mov rax, -2656[rsp]
mov -2664[rsp], rax 	# XC
# XC mod= 10
mov rax, -2664[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2664[rsp], rdx 	# XC
# WC := 48
mov rax, 48
mov -2672[rsp], rax 	# WC
# WC += XC
mov rax, -2672[rsp]
mov rbx, -2664[rsp]
add rax, rbx
mov -2672[rsp], rax 	# WC
# DD := 100
mov rax, 100
mov -2680[rsp], rax 	# DD
# wortel= DD
fildd -2680[rsp]
fsqrt
fistpd -2680[rsp]
# CD := DD
mov rax, -2680[rsp]
mov -2688[rsp], rax 	# CD
# CD /= 1
mov rax, -2688[rsp]
mov rbx, 1
cdq
idivq rbx
mov -2688[rsp], rax 	# CD
# BD := CD
mov rax, -2688[rsp]
mov -2696[rsp], rax 	# BD
# BD mod= 10
mov rax, -2696[rsp]
mov rbx, 10
cdq
idivq rbx
mov -2696[rsp], rdx 	# BD
# AD := 48
mov rax, 48
mov -2704[rsp], rax 	# AD
# AD += BD
mov rax, -2704[rsp]
mov rbx, -2696[rsp]
add rax, rbx
mov -2704[rsp], rax 	# AD
# TB := [UB, YB, CC, GC, KC, OC, SC, WC, AD]
lea rax, -3744[rsp]
mov -3760[rsp], rax
movq -3752[rsp], 9
mov eax, 0x00000000
mov -3744[rsp], eax
movb al, -2544[rsp]
movb -3741[rsp], al
movb al, -2512[rsp]
movb -3742[rsp], al
movb al, -2480[rsp]
movb -3743[rsp], al
movb al, -2448[rsp]
movb -3744[rsp], al
mov eax, 0x00000000
mov -3740[rsp], eax
movb al, -2672[rsp]
movb -3737[rsp], al
movb al, -2640[rsp]
movb -3738[rsp], al
movb al, -2608[rsp]
movb -3739[rsp], al
movb al, -2576[rsp]
movb -3740[rsp], al
mov eax, 0x00
mov -3736[rsp], eax
movb al, -2704[rsp]
movb -3736[rsp], al
lea rax, -3760[rsp]
# ED := [32, 72, 65, 76, 76, 79, 32, 80, 82, 65, 83, 65, 84, 72, 33, 33, 33, 10]
lea rax, -4808[rsp]
mov -4824[rsp], rax
movq -4816[rsp], 18
mov eax, 0x4c414820
mov -4808[rsp], eax
mov eax, 0x50204f4c
mov -4804[rsp], eax
mov eax, 0x41534152
mov -4800[rsp], eax
mov eax, 0x21214854
mov -4796[rsp], eax
mov eax, 0x0a21
mov -4792[rsp], eax
lea rax, -4824[rsp]
# SB := TB
mov rax, -3760[rsp]
mov -4832[rsp], rax 	# SB
# SB ||= ED
mov rax, -4832[rsp]
mov rcx, -4824[rsp]
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
# RB := # SB
mov rbx, -4832[rsp]
mov rax, -8[rbx]
mov -4840[rsp], rax 	# RB
# D := syscall(1, 1, E, RB)
mov rax, 1
mov rdi, 1
mov rsi, -2416[rsp]
mov rdx, -4840[rsp]
syscall
mov -4848[rsp], rax
# C := D
mov rax, -4848[rsp]
mov -4856[rsp], rax 	# C
# C *= 0
mov rax, -4856[rsp]
mov rbx, 0
mul rbx
mov -4856[rsp], rax 	# C
# B := C
mov rax, -4856[rsp]
mov -4864[rsp], rax 	# B
# B += 1
mov rax, -4864[rsp]
mov rbx, 1
add rax, rbx
mov -4864[rsp], rax 	# B
# A := 3 syscall B
mov rax, 3
mov rdi, -4864[rsp]
syscall
mov -4872[rsp], rax
# stop
# exit(0)
mov rdi, 0
mov rax, 60
syscall
ret

