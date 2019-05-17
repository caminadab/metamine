require 'util'

-- swagolienja
function elf(obj)
	local onaam = os.tmpname()
	local enaam = os.tmpname()

	file(onaam, obj)

	os.execute('cc -c -fPIC -masm=intel -DONLY_MSPACES -DNO_MALLOC_STATS bouw/malloc.c')

	os.execute(string.format(
		'ld -G malloc.o %s  -o %s -n --build-id=none -static',
		onaam, enaam
	))
	if not ontkever then
		os.execute(string.format('strip %s', enaam))
	end


	local elf = file(enaam)

	if false then
		os.remove('malloc.o')
		os.remove(onaam)
		os.remove(enaam)
	end
	return elf
end

