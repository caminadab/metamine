.intel_syntax noprefix
.text
.global	_start

.section .text

p1:
mov rcx, -64[rsp]
mov rax, -24[rsp]
mov rdx, -16[rsp]
cmp rcx, 0
cmovg rax, rdx
mov -0[rsp], rax
mov rax, 0
neg rax
mov -8[rsp], rax
mov rax, -8[rsp]
lea rbx, p5[rip]
lea rdx, p6[rip]
cmp rax, 0
jnz p5
jmp rdx
p2:
mov rax, 4
mov -16[rsp], rax
lea rax, p1[rip]
jmp rax
p3:
mov rax, 5
mov -24[rsp], rax
lea rax, p1[rip]
jmp rax
p4:
mov rcx, -8[rsp]
mov rax, -56[rsp]
mov rdx, -48[rsp]
cmp rcx, 0
cmovg rax, rdx
mov -32[rsp], rax
mov rax, -0[rsp]
mov -40[rsp], rax
mov rax, -40[rsp]
mov rbx, -32[rsp]
add rax, rbx
mov -40[rsp], rax
mov rdi, rax
mov rax, 60
syscall
ret

p5:
mov rax, 30
mov -48[rsp], rax
lea rax, p4[rip]
jmp rax
p6:
mov rax, 40
mov -56[rsp], rax
lea rax, p4[rip]
jmp rax
_start:
mov rax, 0
mov -64[rsp], rax
mov rax, -64[rsp]
lea rbx, p2[rip]
lea rdx, p3[rip]
cmp rax, 0
jnz p2
jmp rdx
