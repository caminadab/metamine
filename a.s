.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
mov rcx, -120[rsp]
mov rax, -24[rsp]
mov rdx, -16[rsp]
cmp rcx, 0
cmovg rax, rdx
mov -0[rsp], rax
mov rax, 2
mov rbx, 1
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovg rax, rbx
mov -8[rsp], rax
mov rax, -8[rsp]
lea rbx, p5[rip]
lea rdx, p6[rip]
cmp rax, 0
jnz p5
jmp rdx
p2:
mov rax, 8
mov -16[rsp], rax
lea rax, p1[rip]
jmp rax
p3:
mov rax, -100
mov -24[rsp], rax
lea rax, p1[rip]
jmp rax
p4:
mov rcx, -8[rsp]
mov rax, -64[rsp]
mov rdx, -56[rsp]
cmp rcx, 0
cmovg rax, rdx
mov -32[rsp], rax
mov rax, 0
mov -40[rsp], rax
mov rax, -40[rsp]
mov rbx, -32[rsp]
sub rax, rbx
mov -40[rsp], rax
mov rax, 2
mov rbx, 1
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovg rax, rbx
mov -48[rsp], rax
mov rax, -48[rsp]
lea rbx, p8[rip]
lea rdx, p9[rip]
cmp rax, 0
jnz p8
jmp rdx
p5:
mov rax, 8
mov -56[rsp], rax
lea rax, p4[rip]
jmp rax
p6:
mov rax, -100
mov -64[rsp], rax
lea rax, p4[rip]
jmp rax
p7:
mov rcx, -48[rsp]
mov rax, -112[rsp]
mov rdx, -104[rsp]
cmp rcx, 0
cmovg rax, rdx
mov -72[rsp], rax
mov rax, -40[rsp]
mov -80[rsp], rax
mov rax, -80[rsp]
mov rbx, -72[rsp]
add rax, rbx
mov -80[rsp], rax
mov rax, -0[rsp]
mov -88[rsp], rax
mov rax, -88[rsp]
mov rbx, -80[rsp]
add rax, rbx
mov -88[rsp], rax
mov rax, -88[rsp]
mov -96[rsp], rax
mov rax, -96[rsp]
mov rbx, 2
idivq rbx
mov -96[rsp], rax
mov rdi, rax
mov rax, 60
syscall
ret

p8:
mov rax, 8
mov -104[rsp], rax
lea rax, p7[rip]
jmp rax
p9:
mov rax, -100
mov -112[rsp], rax
lea rax, p7[rip]
jmp rax
_start:
mov rax, 2
mov rbx, 1
cmp rax, rbx
mov rax, 0
mov rbx, 1
cmovg rax, rbx
mov -120[rsp], rax
mov rax, -120[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
