require 'util'

function exe(asm)
	local asmnaam = os.tmpname()
	local objnaam = os.tmpname()
	local exenaam = os.tmpname()

	file(asmnaam, asm)
	os.execute(string.format('x86_64-w64-mingw32-as -g %s.s -o %s.o --no-pad-section -R', asmnaam, exenaam))
	os.execute(string.format('x86_64-w64-mingw32-ld -g %s.o -o %s -n --build-id=none -static', asmnaam, exenaam))
	--os.execute(string.format('strip %s', naam))
	local elf = file(naam)
	--os.remove(naam..'.s')
	--os.remove(naam..'.o')
	--os.remove(naam)
	return elf
end


