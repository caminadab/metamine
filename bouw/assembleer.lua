require 'util'

function assembleer(asm, naam)
	local snaam = os.tmpname()
	local onaam = os.tmpname()

	-- schrijf asm
	file(snaam, asm)

	os.execute(string.format('as -g %s -o %s --no-pad-section -R', snaam, onaam))

	-- lees obj
	local obj = file(onaam)

	-- troep opruimen
	os.remove(snaam)
	os.remove(onaam)

	return obj
end

if test then
	require 'bouw.link'

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
