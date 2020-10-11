require 'util'

function assembleer(asm, name)
	local sname = os.tmpname()
	local oname = os.tmpname()

	-- schrijf asm
	file(sname, asm)

	-- -g
	os.execute(string.format('as %s -o %s --no-pad-section -R', sname, oname))
	--os.execute(string.format('gcc -nostdlib', sname, oname))


	-- lees obj
	local obj = file(oname)

	-- troep opruimen
	if not ontkever then
		os.remove(sname)
	end
	os.remove(oname)

	return obj
end

if test then
	require 'build.link'

	local src = [[
.intel_syntax noprefix
.global start
start:
	mov rax, 60
	mov rdi, 3
	syscall
]]
	local obj = assembleer(src)
	local elf = link(obj)
	local path = os.tmpname()
	file(path, elf)
	os.execute(string.format('chmod +x %s', path))
	local ret = os.execute(path)
	os.remove(path)
	assert(ret/256 == 3, "verkeerde exitcode")
end
