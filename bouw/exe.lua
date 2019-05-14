function exe(asm)
	local naam = os.tmpname()
	local bd = io.open(naam..'.s', 'w')
	bd:write(asm)
	bd:close()
	os.execute(string.format('x86_64-w64-mingw32-as -g %s.s -o %s.o --no-pad-section -R', naam, naam))
	os.execute(string.format('x86_64-w64-mingw32-ld -g %s.o -o %s -n --build-id=none -static', naam, naam))
	--os.execute(string.format('strip %s', naam))
	local elf = file(naam)
	--os.remove(naam..'.s')
	--os.remove(naam..'.o')
	--os.remove(naam)
	return elf
end


