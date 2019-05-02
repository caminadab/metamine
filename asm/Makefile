hoi: hoi.s
	as hoi.s -o hoi.o --no-pad-sections -R
	ld hoi.o -o hoi -n --build-id=none -static
	strip hoi

dump: hoi
	objdump -D hoi -M intel

mul: mul.s
	as mul.s -g -o mul.o --no-pad-sections -R 
	ld mul.o -G -o mul -n --build-id=none -static 

hoi0.s: hoi0.c
	gcc hoi0.c -Os -S -fno-data-sections -nostartfiles -masm=intel

hoi0: hoi0.s
	gcc hoi0.s -Os -Wl,-n -Wl,--build-id=none -Wa,--no-pad-sections -Wa,-R -static -nostartfiles -o hoi0
	strip hoi0
	objcopy --remove-section .comment hoi0
	objcopy --remove-section .tbss hoi0
	objcopy --remove-section .eh_frame hoi0

clean:
	rm *.o

dump0: hoi0
	objdump -D hoi0 -M intel

win64.exe: win64.s
	x86_64-w64-mingw32-gcc -nostdlib -nostartfiles win64.s -luser32
	#-Os -Wl,-n -Wl,--build-id=none -Wa,--no-pad-sections -Wa,-R -static  -o win64.exe
#x86_64-w64-mingw32-as --no-std-lib win64.s -o win64.o --no-pad-sections -R
#x86_64-w64-mingw32-ld -l/usr/x86_64-w64-mingw32/lib/libuser32.a -luser32 -mwindows win64.o -o win64.exe -n --build-id=none -static -luser32

win.exe: win.c
	gcc hoi0.s -Os -Wl,-n -Wl,--build-id=none -Wa,--no-pad-sections -Wa,-R -static -nostartfiles -o hoi0
	#x86_64-w64-mingw32-gcc -S -Os -Wl,-n -Wl,--build-id=none -Wa,--no-pad-sections -Wa,-R -static -nostdlib win.c -o win.exe -luser32

#x86_64-w64-mingw32-as --no-std-lib win64.s -o win64.o --no-pad-sections -R
#x86_64-w64-mingw32-ld -l/usr/x86_64-w64-mingw32/lib/libuser32.a -luser32 -mwindows win64.o -o win64.exe -n --build-id=none -static -luser32
