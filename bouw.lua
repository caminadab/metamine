-- elf x64
function bouw(exp)
	local moet = delta(exp)
	local proc = plan(moet) -- asm secties
	local asm = compileer(proc)
	local obj = assembleer(asm)
	local elf = link(obj)
	return elf
end

