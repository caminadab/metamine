require 'exp'
local fmt = string.format

function codegen(blok, t)
	-- naam -> opslag
	local opslag = {}
	-- stapelgrootte
	local top = 0
	-- instructies
	local t = {}

	-- alloceer
	for i=1,#blok-1 do
		local stat = blok[i]
		local naam = stat[1].v
		if not opslag[naam] then
			opslag[naam] = top
			top = top + 1
		end
	end

	local function laad(reg, val)
		if tonumber(val) then
			t[#t+1] = fmt('mov %s, %s', reg, val)
		else
			assert(opslag[val], val)
			t[#t+1] = fmt('mov %s, [rbp+8*%s]', reg, opslag[val])
		end
	end

	local function opsla(val, reg)
		assert(opslag[val])
		t[#t+1] = fmt('mov [rbp+8*%s], %s', opslag[val], reg)
	end

	-- genereer dan echt
	for i=1,#blok-1 do
		local stat = blok[i]
		local f,naam,exp = fn(stat),stat[1].v,stat[2].v

		if f == ':=' then
			laad('rax', exp)
			opsla(naam, 'rax')
		end

		if f == '+=' then
			laad('rax', naam)
			laad('rbx', exp)
			t[#t+1] = 'add rax, rbx'
			opsla(naam, 'rax')
		end
	end

	-- dit is de nageboorte
	local epiloog = blok[#blok]

	if fn(epiloog) == 'ga' then
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
	end

	return table.concat(t, '\n')
end

if test then
	require 'ontleed'
	local bron = [[
a := 2
b := a
c := a
c += b
;ga a
ga (a, b, c)
]]
	local asm = codegen(ontleed(bron))
	print(asm)
end

