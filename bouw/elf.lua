require 'util'

-- swagolienja
function elf(obj)
	local onaam = os.tmpname()
	local enaam = os.tmpname()

	file(onaam, obj)

	os.execute(string.format(
		'ld %s -o %s -n --build-id=none -static',
		onaam, enaam
	))
	os.execute(string.format('strip %s', enaam))

	local elf = file(enaam)

	if false then
		os.remove(onaam)
		os.remove(enaam)
	end
	return elf
end

