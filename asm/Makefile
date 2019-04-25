hoi: hoi.s
	as hoi.s -o hoi.o --no-pad-sections -R
	ld hoi.o -o hoi -n --build-id=none -static
	strip hoi

dump: hoi
	objdump -D hoi -M intel

hoi0.s: hoi0.c
	gcc hoi0.c -S -fno-data-sections -nostartfiles -masm=intel

hoi0: hoi0.s
	gcc hoi0.s -Wl,-n -Wl,--build-id=none -Wa,--no-pad-sections -Wa,-R -static -nostartfiles -o hoi0
	strip hoi0
	objcopy --remove-section .comment hoi0
	objcopy --remove-section .tbss hoi0
	objcopy --remove-section .eh_frame hoi0

clean:
	rm *.o
