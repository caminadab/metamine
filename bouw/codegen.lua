require 'exp'
require 'bouw.cfg'

local fmt = string.format

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
	for blok in spairs(cfg.punten) do
		labels[blok.naam.v] = true
		for i, stat in ipairs(blok.stats) do
			local naam = stat[1].v
			if not opslag[naam] then
				opslag[naam] = top
				top = top + 1
			end
		end
	end

	local function laad(reg, val)
		if tonumber(val) then
			t[#t+1] = fmt('mov %s, %s', reg, val)
		elseif labels[val] then
			t[#t+1] = fmt('lea %s, rip[%s]', reg, val)
		else
			assert(opslag[val], 'onbekende waarde: '..val)
			t[#t+1] = fmt('mov %s, [rsp+8*%s]', reg, opslag[val])
		end
	end

	local function opsla(val, reg)
		assert(opslag[val])
		t[#t+1] = fmt('mov [rsp+8*%s], %s', opslag[val], reg)
	end

	-- genereer dan echt
	local function blokgen(blok)
		if blok.naam.v == 'start' then
			t[#t+1] = '_start:'
		else
			t[#t+1] = blok.naam.v .. ':'
		end
		for i,stat in ipairs(blok.stats) do
			local f,naam,val,exp = fn(stat),stat[1].v,stat[2].v,stat[2]

			-- vertakkingvrije keus
			if f == ':=' and fn(exp) == '=>' then
				local c,d,a = exp[1],exp[2],exp[3]
				laad('rcx', c.v)
				laad('rax', a.v)
				laad('rdx', d.v)
				t[#t+1] = 'test rcx, rcx'
				t[#t+1] = 'movcc rax, rdx'
				opsla(naam, 'rax')

			elseif f == ':=' and val then
				laad('rax', val)
				opsla(naam, 'rax')

			elseif f == '*=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'mul rbx'
				opsla(naam, 'rax')

			elseif f == '/=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'idivq rbx'
				opsla(naam, 'rax')

			elseif f == '+=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'add rax, rbx'
				opsla(naam, 'rax')

			elseif f == '-=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'sub rax, rbx'
				opsla(naam, 'rax')

			else
				error('onbekende pseudo op: '..f)
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
			if fn(epiloog[1]) ~= ',' then
				laad('rax', epiloog[1].v)
				t[#t+1] = 'jmp rax'
			end

			if fn(epiloog[1]) == ',' then
				laad('rax', epiloog[1][1].v)
				laad('rbx', epiloog[1][2].v)
				laad('rdx', epiloog[1][3].v)
				t[#t+1] = 'cmp rax, 0'
				t[#t+1] = 'jz rbx'
				t[#t+1] = 'jmp rdx'
			end
		
		else
			error('onbekende epiloog: '..exp2string(epiloog))

		end
	end

	for blok in spairs(cfg.punten) do
		blokgen(blok)
	end

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

