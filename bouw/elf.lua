require 'util'

-- swagolienja
function elf(obj, naam)
	local naam = naam or os.tmpname()

	file(naam..'.o', obj)

	--os.execute('cc -c -fPIC -masm=intel -DONLY_MSPACES -DNO_MALLOC_STATS bouw/malloc.c')

	if ontkever then
		print('ONTKEVER')
		os.execute(string.format('ld bieb/malloc.o %s.o -o %s.elf', naam, naam))
	else
		-- malloc.o
		-- WEG -n
		os.execute(string.format( 'ld -O3 bieb/malloc.o %s.o -rpath-link=/lib64/ -dynamic-linker /lib64/ld-linux-x86-64.so.2 -m elf_x86_64 -o %s.elf --build-id=none -lpthread -lxcb', naam, naam))
		--os.execute(string.format('strip %s', naam..'.elf'))
	end


	local elf = file(naam..'.elf')

	if false then
		os.remove('malloc.o')
		os.remove(onaam)
		os.remove(enaam)
	end
	return elf
end

