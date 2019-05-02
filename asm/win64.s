	.intel_syntax noprefix
	.text
	.global	__main

.section .rdata
msg: .string "hoi"
title: .string "Titel"

.section .text

__main:
	sub rsp, 28
	mov rcx, 0       # hWnd = HWND_DESKTOP
	lea rdx, msg[rip]     # LPCSTR lpText
	lea r8,  title[rip]   # LPCSTR lpCaption
	mov r9d, 0       # uType = MB_OK
	call __imp_MessageBoxA
	add rsp, 28 
	ret
