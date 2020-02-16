function ins2asm(ins)
	return "mov eax, ebx"
end
require 'bouw.gen.asmops'

function asmgen(im)
	local L = {}
	L[#L+1] = [[
	.intel_syntax noprefix
	.text
	.global	start

.section .text

start: ]]

	for i, ins in ipairs(im) do
		L[#L+1] = ins2asm(ins)
	end

	L[#L+1] = [[.section .rodata

.groet:
	.string "hoi.txt"
]]

	return table.concat(L,"\n")
end
