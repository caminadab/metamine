require 'exp'
require 'bouw.cfg'

local fmt = string.format

local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
local abiregs = { 'rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9'} -- r10 is static chain pointer in case of nested functions
local registers = { 'r12', 'r13', 'r14', 'r15', 'r10', 'r9', 'r8', 'rcx', 'rdx', 'rsi', 'rdi', 'rax' }
local cmp = {
	['>'] = 'g',
	['>='] = 'ge',
	['='] = 'e',
	['!='] = 'ne',
	['<='] = 'le',
	['<'] = 'l',
}

function codegen(cfg)
	-- naam -> opslag
	local opslag = {}
	-- naam -> proc
	local labels = {}
	-- stapelgrootte
	local top = 0
	-- instructies
	local t = {}

	-- proloog
	t[#t+1] = [[
.intel_syntax noprefix
.text
.global	_start

.section .text
]]

	-- alloceer
	if verbozeOpslag then
		print()
		print('=== OPSLAG ===')
	end
	for blok in spairs(cfg.punten) do
		labels[blok.naam.v] = true
		for i, stat in ipairs(blok.stats) do
			local naam = stat[1].v
			if not opslag[naam] then
				opslag[naam] = top
				top = top + 1
				if verbozeOpslag then
					print(naam..':\tSlot #'..opslag[naam]..', 8 bytes')
				end
			end
		end
	end
	if verbozeOpslag then
		print()
	end

	local function laad(reg, val)
		if val == 'ja' then val = 1 end
		if val == 'nee' then val = 0 end
		if tonumber(val) then
			t[#t+1] = fmt('mov %s, %s', reg, val)
		elseif labels[val] then
			t[#t+1] = fmt('lea %s, %s[rip]', reg, val)
		else
			assert(opslag[val], 'onbekende waarde: '..tostring(val))
			--t[#t+1] = fmt('mov %s, [rsp-8*%s]', reg, opslag[val])
			t[#t+1] = fmt('mov %s, -%d[rsp]', reg, opslag[val] * 8)
		end
	end

	local function opsla(val, reg)
		assert(opslag[val])
		--t[#t+1] = fmt('mov [rsp-8*%s], %s', opslag[val], reg)
		t[#t+1] = fmt('mov -%d[rsp], %s', 8 * opslag[val], reg)
	end

	-- genereer dan echt
	local function blokgen(blok)
		if blok.naam.v == 'start' then
			t[#t+1] = '_start:'
		else
			t[#t+1] = blok.naam.v .. ':'
		end
		for i,stat in ipairs(blok.stats) do
			local op,naam,val,exp = fn(stat),
			stat[1].v,
			stat[2] and stat[2].v,
			stat[2]
			local f = exp and fn(stat[2])

			-- vertakkingvrije keus
			if op == ':=' and f == '=>' then
				local c,d,a = exp[1],exp[2],exp[3]
				laad('rcx', c.v)
				laad('rax', a.v)
				laad('rdx', d.v)
				t[#t+1] = 'cmp rcx, 0'
				t[#t+1] = 'cmovg rax, rdx'
				opsla(naam, 'rax')

			elseif op == ':=' and f == '!' then
				laad('rax', exp[1].v)
				t[#t+1] = 'cmp rax, 0'
				t[#t+1] = 'mov rax, 0'
				t[#t+1] = 'mov rbx, 1'
				t[#t+1] = 'cmove rax, rbx'
				opsla(naam, 'rax')

			elseif op == ':=' and val then
				laad('rax', val)
				opsla(naam, 'rax')

			elseif op == '*=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'mul rbx'
				opsla(naam, 'rax')

			elseif op == '/=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'idivq rbx'
				opsla(naam, 'rax')

			elseif op == '+=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'add rax, rbx'
				opsla(naam, 'rax')

			elseif op == '-=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'sub rax, rbx'
				opsla(naam, 'rax')

			elseif cmp[f] then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'cmp rax, rbx'
				t[#t+1] = 'mov rax, 0'
				t[#t+1] = 'mov rbx, 1'
				t[#t+1] = fmt('cmov%s rax, rbx', cmp[f])
				opsla(naam, 'rax')

			else
				print('F', exp.fn.v, exp2string(exp), cmp[f])
				error('onbekende pseudo ass: '..exp2string(stat))
			end
		end

		-- dit is de nageboorte
		local epiloog = blok.epiloog

		if atoom(epiloog) == 'eind' then
			t[#t+1] = 'ret'

		elseif atoom(epiloog) == 'stop' then
			t[#t+1] = "mov rdi, rax\nmov rax, 60\nsyscall\nret\n"


		elseif fn(epiloog) == 'ga' then
			-- simpele sprong
			if #epiloog ~= 3 and fn(epiloog[1]) ~= ',' then
				laad('rax', epiloog[1].v)
				t[#t+1] = 'jmp rax'
			end

			if #epiloog == 3 then
				laad('rax', epiloog[1].v)
				laad('rbx', epiloog[2].v)
				laad('rdx', epiloog[3].v)
				t[#t+1] = 'cmp rax, 0'
				t[#t+1] = 'jnz '..epiloog[2].v
				t[#t+1] = 'jmp rdx'
			end
		
		else
			error('onbekende epiloog: '..exp2string(epiloog))

		end
	end

	for blok in spairs(cfg.punten) do
		blokgen(blok)
	end
	t[#t+1] = ''

	return table.concat(t, '\n')
end


if test then
	require 'ontleed'
	require 'bouw.blok'

	local code = [[
start:
	c := 1
	d := 2
	a := 3
	e := (als c dan d anders a)
	ga klaar

klaar:
	stop
]]
	local cfg = leescfg(code)
	local asm = codegen(cfg)
	print(asm)

end

