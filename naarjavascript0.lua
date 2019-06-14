require 'util'
require 'func'
require 'symbool'
require 'combineer'

local infix = set('*', '/', '+', '-', 'mod')

local aliases = {
	['..'] = '_toti',
}

local jsbiebbron = file('bieb/bieb.js')

local jsbieb = {}
for waarde, naam in jsbiebbron:gmatch('(var ([^ ]*) = .-\n)\n') do
	jsbieb[naam] = waarde
end

local function sym(exp, t)
	local f = fn(exp)
	local op = f and f:sub(1,-2)
	if infix[op] then
		t[#t+1] = exp[1].v .. op .. exp[2].v
	elseif op == '[]' then
		t[#t+1] = '[' .. table.concat(map(exp, function(sub) return sub.v end), ', ') .. ']'
	else
		if isatoom(exp) then
			t[#t+1] = exp.v
		else
			--t[#t+1] = f .. '(' .. exp[1].v .. ')' --table.concat(map(exp, function(sub) return sub.v end), ', ') .. ')'
			t[#t+1] = f .. '(' .. table.concat(map(exp, function(sub) return sub.v end), ', ') .. ')'
		end
	end
end

--[[
[]       -> []
[](...)  -> [...]
{}(1 2)  -> {1,2}
+(A B)   -> A + B
*(A B)   -> A * B
-(A)     -> - A

sin(A)   -> Math.sin(A)
vanaf(A 1)   -> A.splice(1)
]]
local immjs = {
	['[]'] = '[...]',
	['{}'] = '{}',

	-- arit
	['+i'] = 'A + B',
	['+'] = 'A + B',
	['-'] = 'A + B',
	['*'] = 'A + B',
	['/'] = 'A + B',
	['^'] = 'Math.pow(A, B)',

	-- cmp
	['>'] = 'A > B',
	['>='] = 'A >= B',
	['='] = 'A === B',
	['!='] = 'A !=== B',
	['<='] = 'A <= B',
	['<'] = 'A < B',

	-- trig
	['sin'] = 'Math.sin(A)',
	['cos'] = 'Math.cos(A)',
	['tan'] = 'Math.tan(A)',
	['sincos'] = '[Math.sin(A), Math.cos(A)]',

	-- lijst
	['#'] = 'A.length',

	-- func
	['map'] = 'A.map(B)',

	
	-- LIB
	['print'] = 'print(A)'
}

function naarjavascript0(app)
	local s = {}
	local t = {}
	local maakvar = maakvars()

	local function blokjs(blok)
		for i,stat in ipairs(blok.stats) do
			local naam, exp = stat[1], stat[2]
			local var = maakvar()
			local f = fn(exp)
			local a = exp[1] and exp[1].v
			local b = exp[2] and exp[2].v

			if isatoom(exp) then
				t[#t+1] = string.format('var %s = %s;', naam, exp.v)
			elseif immjs[f] then
				-- a = CMD(a, b)
				local cmd = immjs[f]
				cmd = a and cmd:gsub('A', a) or cmd
				cmd = b and cmd:gsub('B', b) or cmd
				t[#t+1] = string.format('var %s = %s;', naam, cmd)
			elseif bieb[f] then
				t[#t+1] = string.format('var %s = %s(%s);', naam, f, table.concat(map(exp, function(a) return a.v end), ','))
			else
				t[#t+1] = string.format("throw 'onbekende functie: ' + " .. combineer(f) .. ";")
			end
		end
		local epi = blok.epiloog
		if fn(epi) == 'ga' then
			if #epi == 1 then
				t[#t+1] = string.format('if (%s) {')
			end
		end
	end

	for blok in pairs(app.punten) do
		local naam = blok.naam.v
		if blok.naam.v:sub(1,2) == 'fn' then
			t[#t+1] = 'function '..naam..'() {'
			blokjs(blok)
			t[#t+1] = 'return '..blok.stats[#blok.stats][1].v..';'
			t[#t+1] = '}'
		end
	end
	blokjs(app.start)

	return table.concat(s, '\n') .. '\n' .. table.concat(t, '\n')
end

if test then
	require 'bouw.controle'
	require 'bouw.arch'
	require 'ontleed'
	require 'oplos'

	local function moetzijn(broncode, waarde)
		local exp = ontleed(broncode)
		local types = typeer(exp)
		local tussencode = controle(oplos(arch_x64(exp, types), 'uit'))
		local a = naarjavascript0(tussencode)
		a = a .. "\nprint(A)"
		file('a.js', a)
		print(a)
		os.execute('js a.js > a.out')
		local b = file('a.out'):sub(1,-2)
		assert(b == waarde, 'was '..b..' maar moest zijn '..waarde)
	end

	moetzijn("uit = 1 + 1", '2')
end
