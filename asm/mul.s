	.intel_syntax noprefix
	.text
	.global	_start

.section .text

_start:
	# Spannend
	mov rbx, .groet[rip]
	mov rax, 1234
	call atoi

	# Print groet
	mov rax, 1
	mov rdi, 1
	lea rsi, .groet[rip]
	mov rdx, rcx
	syscall

	# Exit
	mov rax, 60
	mov rdi, 0
	syscall
	ret


# rax, rbx -> rax
# int, data -> len
atoi:
	mov rcx, 0  # uitvoerlengte 
	# rbx = data
	# rax = getal
	cmp rax, 0  # getal
	jne eind

nul:
	lea rsi,.groep[rip+eax] # '0'

lus:
	cmp rax, 0
	mov rax,rdx
	mod rdx, 10
	add rdx, '0'
	mov rbx[rcx], rdx
	inc rcx

	div rax, 10
	jmp lus

eind:
	ret

.wection .rwdata

.bestand:
	.string "test.txt"

.groet:
	.string	"hoi\n"
