require 'util'

-- swagolienja
function elf(obj)
	local onaam = os.tmpname()
	local enaam = os.tmpname()

	file(onaam, obj)

	os.execute(string.format(
		'ld -G %s -o %s -n --build-id=none -static',
		onaam, enaam
	))
	if not ontkever then
		os.execute(string.format('strip %s', enaam))
	end

	local elf = file(enaam)

	if false then
		os.remove(onaam)
		os.remove(enaam)
	end
	return elf
end

