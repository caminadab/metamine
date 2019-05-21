require 'util'

-- swagolienja
function elf(obj, naam)
	local naam = naam or os.tmpname()

	file(naam..'.o', obj)

	--os.execute('cc -c -fPIC -masm=intel -DONLY_MSPACES -DNO_MALLOC_STATS bouw/malloc.c')

	if ontkever then
		print('ONTKEVER')
		os.execute(string.format('ld %s.o -o %s.elf', naam, naam))
	else
		-- malloc.o
		os.execute(string.format( 'ld %s.o -o %s.elf -n --build-id=none -static', naam, naam))
		os.execute(string.format('strip %s', naam..'.elf'))
	end


	local elf = file(naam..'.elf')

	if false then
		os.remove('malloc.o')
		os.remove(onaam)
		os.remove(enaam)
	end
	return elf
end

