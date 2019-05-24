require 'exp'
require 'combineer'
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


local function inlinetekst(exp, opslag, loc, t)
	local min,concat = math.min, table.concat
	assert(fn(exp) == '[]')
	-- lengte
	t[#t+1] = fmt('movq %d[rsp], %d', loc, #exp)
	for i=1,#exp,4 do
		local num = {'0x'}
		local s = {}
		for j=min(i+4,#exp),i,-1 do
			print(exp[j].v)
			if tonumber(exp[j].v) then
				num[#num+1] = string.format('%02x', exp[j].v)
			else
				num[#num+1] = '00'
				-- custom pointer
				s[#s+1] = fmt('movb al, %d[rsp]', opslag[exp[j].v])
				s[#s+1] = fmt('movb %d[rsp], al', loc + 8 + (j-1))
			end
		end
		-- getal
		-- sla op
		t[#t+1] = fmt('mov eax, %s', concat(num))
		t[#t+1] = fmt('mov %d[rsp], eax', loc + 8 + (i-1))
		-- extra's
		for i,v in ipairs(s) do
			t[#t+1] = v
		end
	end
end

function codegen(cfg)
	if verbozeAsm then print(); print('=== ASSEMBLEERTAAL ===') end
	-- naam -> opslag
	local opslag = {}
	-- naam -> # slots
	local slots = {}
	-- naam -> proc
	local labels = {}
	-- stapelgrootte
	local top = 0
	-- instructies
	local t = {}

	if verbozeAsm then
		setmetatable(t, {
				__newindex=function(t,k,v)
					rawset(t,k,v)
					print(v)
			end})
	end

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
			local naam,exp,f = stat[1].v, stat[2], stat[2] and fn(stat[2])
			if not opslag[naam] then
				local len = 8
				-- lijst?
				if f == 'b[]' then
					len = #exp + 8
				elseif f == '[]' then
					len = #exp + 8 + 8 -- ptr, len, data
				elseif f == 'd[]' then
					len = 4 * exp + 8
				elseif f == 'q[]' then
					len = 8 * exp + 8
				elseif f == '||' then
					len = 8 + 0x400
				end
				local slot = math.floor(len / 8)
					
				slots[naam] = slot
				top = top - math.ceil(len/8) * 8
				opslag[naam] = top

				if verbozeOpslag then
					print(string.format('%s:\tOffset %d, %d slots, %d bytes', naam, opslag[naam], slot, len))
				end
			end
		end
	end
	if verbozeOpslag then
		print()
	end

	local function laad(reg, val, noot)
		if noot then noot = ' \t# '..noot
		else noot = '' end

		if val == 'ja' then val = 1 end
		if val == 'nee' then val = 0 end
		if tonumber(val) then
			t[#t+1] = fmt('mov %s, %s', reg, val) .. noot
		elseif labels[val] then
			t[#t+1] = fmt('lea %s, %s[rip]', reg, val) .. noot
		else
			assert(opslag[val], 'onbekende waarde: '..tostring(val))
			--t[#t+1] = fmt('mov %s, [rsp-8*%s]', reg, opslag[val])
			t[#t+1] = fmt('mov %s, %d[rsp]', reg, opslag[val]) .. noot
		end
	end

	local function opsla(val, reg, noot)
		if noot then noot = ' \t# '..noot
		else noot = '' end

		assert(opslag[val])
		--t[#t+1] = fmt('mov [rsp-8*%s], %s', opslag[val], reg)
		t[#t+1] = fmt('mov %d[rsp], %s', opslag[val], reg) .. noot
	end

	local maakvar = maakvars()

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
			t[#t+1] = '# '..combineer(stat)

			-- vertakkingsvrije keus
			if op == ':=' and f == '=>' then
				local c,d,a = exp[1],exp[2],exp[3]
				--local lc = #
				laad('rcx', c.v, c.v)
				laad('rax', a.v, a.v)
				laad('rdx', d.v, d.v)
				t[#t+1] = 'cmp rcx, 1'
				t[#t+1] = 'cmove rax, rdx \t# rax = rcx ? rdx : rax'
				opsla(naam, 'rax', naam)

			elseif op == ':=' and f == '!' then
				laad('rax', exp[1].v)
				t[#t+1] = 'cmp rax, 0'
				t[#t+1] = 'mov rax, 0'
				t[#t+1] = 'mov rbx, 1'
				t[#t+1] = 'cmove rax, rbx'
				opsla(naam, 'rax', naam)

			elseif op == ':=' and val then
				laad('rax', val)
				opsla(naam, 'rax', naam)

			elseif op == '*=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'mul rbx'
				opsla(naam, 'rax', naam)

			elseif op == '/=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'idivq rbx'
				opsla(naam, 'rax', naam)

			elseif op == '+=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'add rax, rbx'
				opsla(naam, 'rax', naam)

			elseif op == '-=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'sub rax, rbx'
				opsla(naam, 'rax', naam)

			elseif cmp[f] then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'cmp rax, rbx'
				t[#t+1] = 'mov rax, 0'
				t[#t+1] = 'mov rbx, 1'
				t[#t+1] = fmt('cmov%s rax, rbx', cmp[f])
				opsla(naam, 'rax', naam)

			elseif f == '#' then
				laad('rbx', exp[1].v)
				t[#t+1] = 'mov rax, [rbx]'
				opsla(naam, 'rax', naam)

			elseif f == '[]' then
				--t[#t+0] = fmt('movq %d[rsp], %d', opslag[naam], #exp)
				-- ptr, len, data...
				t[#t+1] = fmt('lea rax, %d[rsp]', opslag[naam]+8) -- sneak de lengte weg
				t[#t+1] = fmt('mov %d[rsp], rax', opslag[naam]) -- sneak de lengte weg
				inlinetekst(exp, opslag, opslag[naam]+8, t)
				t[#t+1] = fmt('lea rax, %d[rsp]', opslag[naam])
				--opsla(naam, 'rax')

			elseif f == '||' then
				local a,b = naam, exp[2].v
				t[#t+1] = fmt('lea rcx, %d[rsp]', opslag[a]+8) -- a.dat
				t[#t+1] = fmt('mov rdx, %d[rsp]', opslag[a]) -- a.len
				t[#t+1] = fmt('lea r8, %d[rsp]', opslag[b]+8) -- b.dat
				t[#t+1] = fmt('mov r9, %d[rsp]', opslag[b]) -- b.len

				-- r3 := a.dat
				-- r3 += r4
				t[#t+1] = fmt('add rcx, rdx')

				-- cat lus
				local label = 'catlus'..maakvar()
				t[#t+1] = fmt('%s:', label)

				t[#t+1] = fmt('dec r9')
				t[#t+1] = fmt('cmp r9, 0')
				t[#t+1] = fmt('jne %s', label)

				t[#t+1] = fmt('lea rax, %d[rsp]', opslag[a])

			elseif f == '||2' then
				local a,b = naam, exp[2].v
				-- rax: i: #a..#b
				local label = 'catlus'..maakvar()
				t[#t+1] = fmt('lea r8, %d[rsp]', opslag[b]+8) -- b.dat
				t[#t+1] = fmt('mov rcx, %d[rsp]', opslag[b]) -- b.len
				t[#t+1] = 'mov r9, r8'
				t[#t+1] = 'dec rcx'
				t[#t+1] = fmt('lea rbx, %d[rsp]', opslag[a]+8) -- a.dat
				t[#t+1] = fmt('mov rax, %d[rsp]', opslag[a]) -- a.len
				t[#t+1] = 'mov rdx, rbx'
				t[#t+1] = 'add r9, rax'
				t[#t+1] = 'add rbx, rax' -- a + a.len
				t[#t+1] = label..':'
				t[#t+1] = fmt('mov rax, [rbx]') -- 
				t[#t+1] = fmt('mov [r12], rax')
				t[#t+1] = 'dec rcx'
				t[#t+1] = 'dec r12'
				t[#t+1] = 'cmp rcx, -1'
				t[#t+1] = 'jne '..label

				-- nieuwe lengte
				t[#t+1] = 'mov [rdx], rbx'
				t[#t+1] = 'mov rax, rdx'
				opsla(naam, 'rax')

			else
				error('onbekende pseudo ass: '..combineer(stat))
			end
		end

		-- dit is de nageboorte
		local epiloog = blok.epiloog
		t[#t+1] = '# '..combineer(epiloog)

		if atoom(epiloog) == 'eind' then
			t[#t+1] = 'ret'

		elseif atoom(epiloog) == 'stop' then
			local naam = blok.stats[#blok.stats][1]
			t[#t+1] = "mov rdi, 1" -- string
			t[#t+1] = fmt("mov rsi, %d[rsp]", opslag[naam.v])  -- buf
			t[#t+1] = "movq rdx, [rsi]" -- len
			t[#t+1] = "add rsi, 8" -- len
			t[#t+1] = "mov rax, 1" -- write
			t[#t+1] = "syscall"

			t[#t+1] = '# exit(0)'
			t[#t+1] = "mov rdi, 0\nmov rax, 60\nsyscall\nret\n"


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

	for blok in pairs(cfg.punten) do
		if blok.naam == 'start' then
			blokgen(blok)
		end
	end
	for blok in spairs(cfg.punten) do
		if blok.naam ~= 'start' then
			blokgen(blok)
		end
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

