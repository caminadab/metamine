	.intel_syntax noprefix
	.text
	.global	_start

.section .text

_start:
	# Print groet
	mov rax, 1
	mov rdi, 1
	lea rsi, .groet[rip]
	mov rdx, 4
	syscall

	# Open bestand
	mov rax, 2
	lea rdi, .bestand[rip]
	mov rsi, 0x40
	mov rdx, 0644
	syscall

	# Sluit bestand
	mov rdi, rax
	mov rax, 3
	syscall

	# Exit
	mov rax, 60
	mov rdi, 0
	syscall
	ret

.section .rodata

.bestand:
	.string "test.txt"

.groet:
	.string	"hoi\n"
