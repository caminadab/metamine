	.intel_syntax noprefix

.section .rdata
msg: .string "hoi"
title: .string "Titel"

.section .text

	.text
	.global	_start

_start:
	sub rsp, 28

	mov rcx, 0
	mov rdx, msg[rip]
	mov r8, 3
	lea r9, [rsp]
	push 0
	call __imp_WriteConsoleA[rip]

	mov rcx, 0       # hWnd = HWND_DESKTOP
	lea rdx, msg[rip]     # LPCSTR lpText
	lea r8,  title[rip]   # LPCSTR lpCaption
	mov r9d, 0       # uType = MB_OK
	call __imp_MessageBoxA[rip]
	add rsp, 28 
	ret
