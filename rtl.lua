require 'exp'
require 'func'
local fmt = string.format

local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
local registers = { 'r12', 'r13', 'r14', 'r15', 'rbx', 'rdx', 'rsp', 'rbp', 'rsi', 'rdi', 'r8', 'r9', 'r10', 'rax' }
for i, register in pairs(registers) do
	registers[register] = i
end

local syscalls = {}
local f = io.open('data/syscalls')
for syscall in f:lines() do
	syscalls[#syscalls+1] = syscall
	syscalls[syscall] = #syscalls-1
end


local cmpops = {
	['='] = 'je', ['!='] = 'jne',
	['>'] = 'jg', ['<'] = 'jl',
	['>='] = 'jge', ['<='] = 'jle',
}

function assembleer(stats)
	local regs = {} -- reg -> var, var -> reg
	local tijd = {} -- reg -> vanaf
	for i,reg in ipairs(registers) do tijd[reg] = 0 end

	local d = {} -- data
	local t = {} -- code

	local function maakvrij(reg)
		if not regs[reg] then
			-- hij is al vrij
			return nil
		end
		--assert(reg, error('geen reg'))
		for i,ander in ipairs(registers) do
			if not regs[ander] then
				-- hij is vrij! hernoem
				t[#t+1] = fmt('mov %s, %s', ander, reg)
				local var = regs[reg]
				--regs[andervar] = ander -- dit hoeft dus niet
				regs[ander] = var
				regs[var] = ander
				regs[reg] = nil
				return ander
			end
		end
		error "te weinig registers"
	end

	local function herstel(reg, waarde)
		if waarde then
			t[#t+1] = fmt('mov %s, %s', reg, waarde)
		end
	end

	local i = 0
	function regalloc()
		print('ALLOC '..i)
		local reg = registers[i + 1]
		i = (i + 1) % #registers
		maakvrij(reg)
		return reg
	end

	local cmp
	for i,stat in ipairs(stats) do
		-- wat moet er berekent worden
		local naam,exp
		if stat.fn and stat.fn.v == ':=' then
			naam,exp = stat[1],stat[2]
		else
			exp = stat
		end

		if false and naam then
			local doelreg = regalloc()
		end

		-- b(0) := 'O'
		if naam and isfn(naam) then
			assert(exp.v, "kan alleen atomaire waarden in lijsten stoppen")
			local addr = regalloc()
			t[#t+1] = fmt('lea %s, [%s+%s]', addr, regs[naam.fn.v], naam[1].v)
			t[#t+1] = fmt('movb [%s], %s', addr, exp.v)

		-- compare
		elseif exp.fn and cmpops[exp.fn.v] then
			assert(regs[exp[1].v], exp[1].v)
			assert(regs[exp[2].v], exp[2].v)
			local a = regs[exp[1].v]
			local b = regs[exp[2].v]
			t[#t+1] = string.format('cmp %s, %s', a, b)
			cmp = cmpops[exp.fn.v]

		-- label
		elseif exp.fn and exp.fn.v == 'label' then
			local lbl = exp[1].v
			if lbl == 'start' then lbl = '_start' end
			t[#t+1] = lbl .. ':'

		-- data
		elseif exp.fn and exp.fn.v == '[]' then
			assert(naam, 'data heeft geen naam')
			local t = {}
			for i=1,#exp do t[i] = exp[i].v end
			d[#d+1] = naam.v..': '..'.byte '..table.concat(t, ',')

		-- stack
		elseif exp.fn and exp.fn.v == 'data' then
			t[#t+1] = 'sub rsp, '..exp[1].v
			local reg = regalloc()
			t[#t+1] = fmt('lea %s, [rsp]', reg)
			regs[reg] = assert(naam.v)
			regs[naam.v] = assert(reg)

		-- syscall
		elseif exp.fn and syscalls[exp.fn.v] then
			local r = maakvrij('rax')
			t[#t+1] = string.format('mov rax, %d', syscalls[exp.fn.v])
			regs.rax = syscalls[exp.fn.v]
			local args = exp[1]
			if isatoom(args) then
				args = {args}
			end
			local a = {}
			for i,arg in ipairs(args) do
				-- in gebruik?
				a[i] = maakvrij(sysregs[i])
				if regs[arg.v] then 
					t[#t+1] = string.format('mov %s, %s', sysregs[i], regs[arg.v])
				elseif tonumber(arg.v) then
					t[#t+1] = string.format('mov %s, %s', sysregs[i], arg.v)

				elseif false and labels[arg.v] then
					--t[#t+1] = string.format('lea %s, %s[rip]', sysregs[i], labels[arg.v])
				else
				print('ARG',exp2string(arg))
					t[#t+1] = string.format('lea %s, %s[rip]', sysregs[i], arg.v)
					--error(arg.v..' is onbekend')
				end
			end
			print(exp2string(exp))
			--for i,v in pairs(exp
			t[#t+1] = 'syscall\n'

			herstel('rax', r)
			for i,w in ipairs(a) do
				herstel(sysregs[i], w)
			end

		elseif exp.fn and exp.fn.v == '+=' then
			t[#t+1] = fmt('add %s, %s', regs[exp[1].v], exp[2].v)

		-- jump
		elseif exp.fn and exp.fn.v == 'ga' then
			if exp[1].v == 'start' then exp[1].v = '_start' end
			t[#t+1] = 'jmp '..exp[1].v

		elseif exp.fn and exp.fn.v == '=>' then
			assert(cmp)
			assert(exp[2].fn.v == 'ga')
			t[#t+1] = string.format('%s %s', cmp, exp[2][1].v)
			cmp = nil

		elseif tonumber(exp.v) then
			assert(naam, "nutteloze opdracht gevonden: "..exp2string(stat))
			local doel = regalloc()
			regs[doel] = exp.v
			regs[naam.v] = doel
			tijd[doel] = #t + 1
			t[#t+1] = string.format('mov %s, %s', doel, exp.v)

		elseif exp.fn and exp.fn.v then
			t[#t+1] = 'call '..exp.fn.v

		else
			error(exp2string(exp))
		end
	end

	local header = [[
.intel_syntax noprefix
.text
.global	_start

.section .text

]]

	return header .. table.concat(t, '\n') .. '\n' .. table.concat(d, '\n') .. '\n'
end

--[[
a := 3
	sub rsp, 4
	rax(a) =
		mov rax, 3

a := data(4)
	sub rsp, 4
	a = start.rbp + 4
	rax(a) =
		lea rax, [start.rbp - 4]

a := "hoi\n"
	.a: .string "hoi\n"
	rax(a) =
		lea rax, .a[rip]

]]

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
	local b = file 'b.rtl'
	b = b:gsub('\t','')
	b = b:gsub('(%w+):[^=]', function(lbl) return '\nlabel '.. lbl..'\n' end)
	print(b)
	local rtl = O(b)
	print(exp2string(rtl))

	require 'exp'
	local asm = assembleer(rtl)
	print(asm)
	local elf = elf(asm)
	file('a.s', asm)
	file('a.elf', elf)
	os.execute('chmod +x a.elf')
	os.execute('./a.elf')
end
