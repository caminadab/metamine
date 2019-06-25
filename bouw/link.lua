require 'util'

-- swagolienja
function link(obj)
	local objnaam = os.tmpname()
	local elfnaam = os.tmpname()

	file(objnaam, obj)

	if ontkever then
		print('ONTKEVER')
		os.execute(string.format('ld -estart bieb/malloc.o %s -o %s', objnaam, elfnaam))
	else
		-- WEG -n
		-- MET -s (strip)
		os.execute(string.format(
		'ld -estart -O2 bieb/malloc.o %s'
			.. ' -rpath-link=/lib64/ -dynamic-linker /lib64/ld-linux-x86-64.so.2'
			.. ' -m elf_x86_64 -o %s --build-id=none'
			.. ' -lpthread -lxcb',
			objnaam, elfnaam))
	end

	local elf = file(elfnaam)

	os.remove(objnaam)
	os.remove(elfnaam)

	return elf
end
