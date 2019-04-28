local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
local registers = { 'rax', 'rcx', 'rdx', 'rbx', 'rsp', 'rbp', 'rsi', 'rdi', 'r8', 'r9', 'r10', 'r11', 'r12', 'r13', 'r14', 'r15' }
for i, register in pairs(registers) do
	registers[register] = i
end

local syscalls = {}
local f = io.open('data/syscalls')
for syscall in f:lines() do
	syscalls[#syscalls+1] = syscall
	syscalls[syscall] = #syscalls-1
end

local function syscall(exp, r)
	r[#r+1] = string.format('\tmov rax, %d\n', syscalls[exp.fn.v])
	if exp[1].fn and exp[1].fn.v == ',' then
		for i,arg in ipairs(exp[1]) do
			if not tonumber(arg.v) then
				arg = '.'..arg.v
				r[#r+1] = string.format('\tlea %s, %s[rip]\n', sysregs[i], arg)
			else
				arg = arg.v
				r[#r+1] = string.format('\tmov %s, %s\n', sysregs[i], arg)
			end
		end
	else
		local i,arg = 1,exp[1]
		r[#r+1] = string.format('\tmov %s, %s\n', sysregs[i], exp2string(arg))
	end
	r[#r+1] = '\tsyscall\n'
end

function assembleer(rtl)
	local d = {}
	local r = {}
	local t = r
	local l = {}
	local di, ri = 0, 0

	-- reg -> varnaam
	local regs = {}
	-- varnaam -> data
	local vars = {}
	-- varnaam -> label
	local labels = {}

	local function maakvrij(reg)
		if regs[reg] and vars[regs[reg]] then
			t[#t+1],t[#t+2],t[#t+3],t[#t+4] = '\tmov ',regs[reg],', ',vars[regs[reg]]
		end
	end
	
	local function mov(reg, waarde, t)
	end

	local function emitdata(n,d)
		if type(n.v) == 'number' then
			d[#d+1] = '.d'..di..':\n'
			d[#d+1] = '\t.zero '..n.v..'\n'
		else
			assert(isfn(n))
			d[#d+1] = '.d'..di..':\n\t.byte '
			for i,arg in ipairs(n) do
				d[#d+1] = tostring(arg.v)
				if i ~= #n then d[#d+1] = ',' end
			end
			d[#d+1] = '\n'
		end
		di = di + 1
	end

	for i,stat in ipairs(rtl) do
		local x,v = stat[1],stat[2]
		if not v then --stat.fn and stat.fn.v == ':=' then
			v = stat
		end
		local f = v.fn and v.fn.v or v.v

		-- data
		if f == 'data' or f == '[]' then
			emitdata(v,r)

		elseif f == 'eind' then
			r[#r+1] = '\tret\n'

		elseif f == '*' then
			-- maak ze vrij
			maakvrij(registers.r)
			r[#r+1] = '\tmul\n'
			--if not regs[v[2]] and regs[v[1]] then
			--	regs

		-- maak vrij
		--for naam in pairs(var(v)) do
			--maakvrij(

		elseif syscalls[f] then
			maakvrij(registers.rax)
			for i in ipairs(v) do maakvrij(sysregs[i]) end
			syscall(v, r)

			regs.rax = x
		end
	end
	local header = [[
.intel_syntax noprefix
.text
.global	_start

.section .text

_start:
]]
	return header .. table.concat(r) .. table.concat(d)
end

-- swagolienja
function elf(asm)
	local naam = os.tmpname()
	local bd = io.open(naam..'.s', 'w')
	bd:write(asm)
	bd:close()
	os.execute(string.format('as %s.s -o %s.o --no-pad-section -R', naam, naam))
	os.execute(string.format('ld %s.o -o %s -n --build-id=none -static', naam, naam))
	os.execute(string.format('strip %s', naam))
	local elf = file(naam)
	os.remove(naam..'.s')
	os.remove(naam..'.o')
	os.remove(naam)
	return elf
end

if true or test then
	require 'ontleed'
	local O = ontleed
	local rtl = O[[

d0 := data(1000)
d1 := "hoi\n"
r0 := read(0, d0, 1000)
r1 := write(1, d1, 4)
r2 := write(1, d0, r0)
r3 := exit(0)

]]
	require 'util'
	local rtl = O(file('a.rtl'))

	require 'exp'
	local asm = assembleer(rtl)
	print(asm)
	local elf = elf(asm)
	file('a.elf', elf)
	os.execute('chmod +x a.elf')
	os.execute('./a.elf')
end
