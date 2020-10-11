require 'util'

function exe(asm)
	local asmname = os.tmpname()
	local objname = os.tmpname()
	local exename = os.tmpname()

	file(asmname, asm)
	os.execute(string.format('x86_64-w64-mingw32-as -g %s.s -o %s.o --no-pad-section -R', asmname, exename))
	os.execute(string.format('x86_64-w64-mingw32-ld -g %s.o -o %s -n --build-id=none -static', asmname, exename))
	--os.execute(string.format('strip %s', name))
	local elf = file(name)
	--os.remove(name..'.s')
	--os.remove(name..'.o')
	--os.remove(name)
	return elf
end


