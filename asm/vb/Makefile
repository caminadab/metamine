vb: main.c
	gcc -Wl,--build-id=none -Wa,--no-pad-sections -Wa,-R -Os main.c -lSDL2 -o vb 
	objcopy --remove-section .comment vb
	objcopy --remove-section .eh_frame vb
	strip -S vb
	strip -s vb
