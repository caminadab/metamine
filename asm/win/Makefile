hoi: hoi.s
	x86_64-w64-mingw32-gcc -nostdlib hoi.s -lkernel32 -luser32 -o hoi.exe
	#strip hoi.exe

hoi0: hoi0.s
	x86_64-w64-mingw32-gcc -nostdlib hoi0.s -luser32 -o hoi0.exe
	#strip hoi0.exe

hoi1: hoi1.c
	x86_64-w64-mingw32-gcc -S -Os -masm=intel -nostdlib hoi1.c -luser32 -lkernel32 -o hoi1.s
	x86_64-w64-mingw32-gcc    -Os             -nostdlib hoi1.c -luser32 -lkernel32 -o hoi1.exe
	#strip hoi1.exe

win: win.c
	x86_64-w64-mingw32-gcc -S -Os -masm=intel  win.c -lgdi32 -luser32 -lkernel32 -o win.s
	x86_64-w64-mingw32-gcc    -Os              win.c -lgdi32 -luser32 -lkernel32 -o win.exe
