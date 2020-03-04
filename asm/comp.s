# Compositie oefening

.intel_syntax noprefix
.text
.global	_start

.section .text

_start:

	mov rax, 1
	mov rdi, 1
	lea rsi, .groet[rip]
	mov rdx, 4
	syscall

	# Open bestand
	call inc

	# Exit
	mov rax, 60
	mov rdi, 3
	syscall
	ret

# Increment function
inc:
	mov rax, 1
	ret
	

.section .rodata

.bestand:
	.string "test.txt"

.groet:
	.string	"hoi\n"
