require 'util'

-- swagolienja
function elf(obj, naam)
	local naam = naam or os.tmpname()

	file(naam..'.o', obj)

	--os.execute('cc -c -fPIC -masm=intel -DONLY_MSPACES -DNO_MALLOC_STATS bouw/malloc.c')

	os.execute(string.format(
		'ld '..--[[malloc.o]]' %s.o -o %s.elf -n --build-id=none -static',
		naam, naam
	))
	if true and not ontkever then
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

