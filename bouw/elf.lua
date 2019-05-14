require 'util'

-- swagolienja
function elf(asm)
	local onaam = os.tmpname()
	local enaam = os.tmpname()

	os.execute(string.format(
		'ld -G %s -o %s -n --build-id=none -static',
		onaam, enaam
	))
	os.execute(string.format('strip %s', naam))
	os.remove(onaam)

	local elf = file(enaam)
	os.remove(enaam)
	return elf
end

