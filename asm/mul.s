	.intel_syntax noprefix
	.text
	.global	_start

.section .text

_start:
	# Spannend
	mov rax, 1234567
	sub rsp, 64
	mov rcx, rsp
	call atoi

	# Print groet
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, r8
	syscall

	# Exit
	mov rax, 60
	mov rdi, 0
	syscall
	ret


# int, data -> len
# rax, rcx -> r8
atoi:
	mov r9, rcx # waar zijn we
	cmp rax, 0  # getal
	jne lus

nul:
	inc rcx
	movb [rcx], '0'
	jmp eind

lus:
	cmp rax, 0
	je eind
	cdq
	mov rbx, 10
	idiv rbx
	add rdx, '0'
	mov rbx, rdx
	movb [rcx], bl
	inc rcx
	jmp lus

eind:
	mov r8, rcx
	sub r8, rsp
	ret

.groet:
	.string	"hoi\n"
