require 'mmap'
require 'symbool'
require 'stroom'

require 'ontleed'
local O = ontleedexp

-- mmap(Δexp)
-- mmap((exp.i, exp))
function delta(uit)
	local moet = mmap()
	moet[sym.start] = X("||=", 'uit', exp)
	-- exp = I
	-- g = tijd ⇒ uit
	-- g: altijd ⇒ (stduit = 'hoi')
	-- g' = moment ⇒ Δuit
	-- g': start ⇒ (stduit ||= 'hoi')
	-- f = x → y
	-- f' = 1
	-- 1' = 0
	-- 
	return moet
end

--[[
uit = in

Δuit = Δin
]]

-- moment → (exp' → exp)
function plan(moet)
	-- plaats functies aan het eind
	local start = {}
	for moment,delta in pairs(moet) do
		if moment == sym.start then
			start[#start+1] = delta
		else
			print('Onbekend tijdstip: '..moment)
		end
	end
	local planning = stroom()
	planning:link(set(), start)
	return planning
end

-- → asm_x64
function compileer(proc)
	local t = {}

	local i = 0
	local function reg()
		local r = "r" .. i
		i = i + 1
		return r
	end
	local regs = {}
	local pool = {}

	local di = 0
	local function data(exp)
		local d = 'd' .. di
		data[exp] = X'd'
		di = di + 1
		return d
	end

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
		t[i] = exp2string(v)
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
	print(asm)
	do return asm end
	local obj = assembleer(asm)
	local elf = link(obj)
	return elf
end

if false and test then
	require 'oplos'

	verboos = true
	bouw(oplos(ontleed[[
uit ||= "ja" als start
uit ||= "hoi" als looptijd = 1
	]], 'uit'))
end
