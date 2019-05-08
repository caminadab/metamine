
label start
d := data(20)
a := 123456789
len := atoi(a, d)
write(1, d, len)
exit(0)
eind


label atoi
i := arg(0)
str := arg(1)
len := 0

z := 0
b := (i != z)
ga lus als b


label nul
str(0) := '0'
len += 1
len


label lus
tien := 10
(i,d) /= tien
z := 0
y := (i = z)
ga klaar als y
e := '0'
e += d
str(len) := e
len += 1
ga lus


label klaar
len


EN[31m([97m
  label[32m([97mstart[32m)[97m 
  :=[32m([97md data[33m([97m20[33m)[97m[32m)[97m 
  :=[32m([97ma 123456789[32m)[97m 
  :=[32m([97mlen atoi[33m([97m,[35m([97ma d[35m)[97m[33m)[97m[32m)[97m 
  write[32m([97m,[33m([97m1 d len[33m)[97m[32m)[97m 
  exit[32m([97m0[32m)[97m 
  eind 
  label[32m([97matoi[32m)[97m 
  :=[32m([97mi arg[33m([97m0[33m)[97m[32m)[97m 
  :=[32m([97mstr arg[33m([97m1[33m)[97m[32m)[97m 
  :=[32m([97mlen 0[32m)[97m 
  :=[32m([97mz 0[32m)[97m 
  :=[32m([97mb !=[33m([97mi z[33m)[97m[32m)[97m 
  =>[32m([97mb ga[33m([97mlus[33m)[97m[32m)[97m 
  label[32m([97mnul[32m)[97m 
  :=[32m([97mstr[33m([97m0[33m)[97m 48[32m)[97m 
  +=[32m([97mlen 1[32m)[97m 
  len 
  label[32m([97mlus[32m)[97m 
  :=[32m([97mtien 10[32m)[97m 
  /=[32m([97m,[33m([97mi d[33m)[97m tien[32m)[97m 
  :=[32m([97mz 0[32m)[97m 
  :=[32m([97my =[33m([97mi z[33m)[97m[32m)[97m 
  =>[32m([97my ga[33m([97mklaar[33m)[97m[32m)[97m 
  :=[32m([97me 48[32m)[97m 
  +=[32m([97me d[32m)[97m 
  :=[32m([97mstr[33m([97mlen[33m)[97m e[32m)[97m 
  +=[32m([97mlen 1[32m)[97m 
  ga[32m([97mlus[32m)[97m 
  label[32m([97mklaar[32m)[97m 
  len
[31m)[97m
r12	d
r13	a
rax	len
rdi	1
rdi	0
rdi	i
rsi	str
r15	z
r10	60
r9	tien
rcx	e
.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
sub rsp, 20
lea r12, [rsp]
mov r13, 123456789
mov rdi, r13  # argument
mov rsi, r12  # argument
call atoi
mov r14, rax  # maak ruimte
mov rax, 1
mov rdi, 1
mov rsi, r12
mov rdx, r14
syscall  # write
mov r15, rax  # maak ruimte
mov rax, 60
mov r10, rdi  # maak ruimte
mov rdi, 0
syscall  # exit
ret

atoi:
mov r9, r14  # maak ruimte
mov r14, 0
mov r8, r15  # maak ruimte
mov r15, 0
cmp rdi, r15
jne lus
nul:
mov rcx, r10  # maak ruimte
mov r10, rax  # maak ruimte
mov rax, 48 	# zet str 0
lea r10, [rsi+rdi] 	# offset
movb [r10], al 	# indexed assign
inc r14
mov rax, r14
ret

lus:
mov rax, r9  # maak ruimte
mov r9, 10
push rdi
mov rdi, rax  # maak ruimte
mov rax, nil
xor rdx, rdx
idivq r9
mov nil, rax
mov rax, r8  # maak ruimte
mov r8, 0
cmp nil, r8
je klaar
push r10
mov rcx, 48
add rcx, rdx
mov r10, rdx  # maak ruimte
mov rdx, rax  # maak ruimte
mov rax, rcx 	# zet str len
lea rdx, [rsi+rdi] 	# offset
movb [rdx], al 	# indexed assign
inc rdi
jmp lus
klaar:
mov rax, rdi
ret



