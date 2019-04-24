require 'mmap'
require 'symbool'
require 'stroom'

require 'ontleed'
local O = ontleedexp

function delta(exp)
	local moet = mmap()
	moet.start = sym.maplet(sym.niets, exp)
	return moet
end

function plan(moet)
	local start = {}
	for moment,delta in pairs(moet) do
		print('MD', moment, exp2string(delta))
		if moment == 'start' then
			print 'ja'
		end
	end
	error('ok')
	local uit = O"(uit := 3)"
	local graaf = stroom()
	--graaf:link(set"hoi", "a")
	print(graaf)
	return graaf
end

function compileer(proc)
	local t = {}
	for i,brok in pairs(proc:topologisch()) do
		for _,w in ipairs(brok) do
			t[#t+1] = "add eax, ebx ;" .. exp2string(w)
		end
	end
	return table.concat(t, '\n')
end

function assembleer(asm)
	return "ja doei"
end

function link(obj)
	return "\x31 ELF"
end

-- elf x64
function bouw(exp)
	local moet = delta(exp)
	local proc = plan(moet) -- asm secties
	do return end
	local asm = compileer(proc)
	local obj = assembleer(asm)
	local elf = link(obj)
	return elf
end

if test then
	require 'oplos'

	verboos = true
	bouw(oplos(ontleed'uit = a\na = "3"', X'uit'))
end
