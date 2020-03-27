.686
.model flat, stdcall

EXTERN MessageBoxA@16 : proc
EXTERN ExitProcess@4 : proc

.const
msgText db 'Windows assembly language lives!', 0
msgCaption db 'Hello World', 0

.code
Main:
push 0
push offset msgCaption
push offset msgText
push 0
call MessageBoxA@16
push eax
call ExitProcess@4

End Main
