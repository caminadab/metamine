require 'mmap'
require 'symbool'
require 'stroom'

require 'ontleed'
local O = ontleedexp

-- mmap(Δexp)
function delta(exp)
	local moet = mmap()
	moet[sym.start] = sym.maplet(sym.niets, exp)
	return moet
end

-- → graaf(lijst(
function plan(moet)
	local start = {}
	for moment,delta in pairs(moet) do
		if moment == sym.start then
			start[#start+1] = delta[2]
		else
			print('Onbekend tijdstip: '..moment)
		end
	end
	local graaf = stroom()
	graaf:link(set(), start)
	return graaf
end

-- → asm_x64
function compileer(proc)
	local t = {}

	local i = 0
	function reg()
		local r = "r" .. i
		i = i + 1
		return r
	end
	local regs = {}

	for i,brok in pairs(proc:topologisch()) do
		for _,w in ipairs(brok.naar) do
			-- nu per 1 valuatie
			for node in boompairsdfs(w) do
				if tonumber(node.v) then
					local r = reg()
					local val = X(':=', r, node) 
					regs[node] = r
					t[#t+1] = val
				elseif isfn(node) then
					local r = reg()
					local ass = X(':=', r, X(node.fn.v, regs[node[1]], regs[node[2]], regs[node[3]]))
					t[#t+1] = ass
					regs[node] = r
				end
			end
		end
	end
	for i, v in ipairs(t) do
		print(exp2string(v))
	end
	return table.concat(t, '\n')
end

function assembleer(asm)
	file('.tmp.asm', asm)
	os.execute('as -msyntax=intel .tmp.asm -o .tmp.obj')
	local obj = file('.tmp.obj')
	--os.execute('rm .tmp.asm .tmp.obj')
	return obj
end

function link(obj)
	return "\x31 ELF"
end

-- elf x64
function bouw(exp)
	local moet = delta(exp)
	local proc = plan(moet) -- asm secties
	local asm = compileer(proc)
	do return end
	local obj = assembleer(asm)
	local elf = link(obj)
	return elf
end

if test or true then
	require 'oplos'

	verboos = true
	bouw(oplos(ontleed[[
uit = "som is " || s
s = Σ 1 .. 1000
	]], 'uit'))
end
