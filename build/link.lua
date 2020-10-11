require 'util'

-- swagolienja
function link(obj)
	local objname = os.tmpname()
	local elfname = os.tmpname()

	file(objname, obj)

	if ontkever then
		print('ONTKEVER')
		os.execute(string.format('ld -estart %s -o %s', objname, elfname))
	else
		-- WEG -n
		-- MET -s (strip)
		os.execute(string.format(
		'ld -estart %s'
			.. ' -rpath-link=/lib64/ -dynamic-linker /lib64/ld-linux-x86-64.so.2'
			.. ' -m elf_x86_64 -o %s --build-id=none'
			.. ' -lpthread -lxcb',
			objname, elfname))
	end

	local elf = file(elfname)

	os.remove(objname)
	os.remove(elfname)

	return elf
end
