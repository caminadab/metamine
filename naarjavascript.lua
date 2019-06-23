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
	['[]'] = '[ARGS]',
	['{}'] = 'new Set(ARGS)',
	['{}'] = '{}',
	['_arg'] = '_argA',

	-- arit
	['+i'] = 'X + Y',
	['+'] = 'X + Y',
	['-'] = 'X - Y',
	['*'] = 'X * Y',
	['/'] = 'X / Y',
	['mod'] = 'X % Y',
	['^'] = 'Math.pow(X, Y)',

	-- cmp
	['>'] = 'X > Y',
	['>='] = 'X >= Y',
	['='] = 'X === Y',
	['!='] = 'X !=== Y',
	['<='] = 'X <= Y',
	['<'] = 'X < Y',

	-- deduct
	['en'] = 'X && Y', 
	['of'] = 'X || Y', 
	['=>'] = 'X ? Y : Z', 

	-- trig
	['sin'] = 'Math.sin(X)',
	['cos'] = 'Math.cos(X)',
	['tan'] = 'Math.tan(X)',
	['sincos'] = '[Math.sin(X), Math.cos(X)]',

	-- discreet
	['min'] = 'Math.min(X,Y)',
	['max'] = 'Math.max(X,Y)',
	['entier'] = 'Math.floor(X)',
	['abs'] = 'Math.abs(X)',
	['sign'] = '(X > 0 ? 1 : -1)',

	-- exp
	['log10'] = 'Math.log(X, 10)',
	['||'] = 'X.concat(Y)',

	-- lijst
	['#'] = 'X.length',
	['som'] = 'X.reduce((a,b) => a + b, 0)',
	['..'] = 'Array.from({length: Math.abs(Y-X)}).map(a => X > Y? a + X : X + Y - 2 - a)',
	['_'] = 'X[Y]',
	['call'] = 'X(Y)',

	-- func
	['map'] = 'X.map(Y)',

	
	-- LIB
	['tekst'] = 'Array.isArray(X) ? X.map(String.fromCharCode).reduce((a,b) => a + b) : X.toString()',
	['print'] = 'console.log(X)',
}

function naarjavascript(app)
	local s = {}
	local t = {}
	local maakvar = maakvars()

	local function blokjs(blok, tabs)
		for i,stat in ipairs(blok.stats) do
			local naam, exp = stat[1], stat[2]
			local var = maakvar()
			local f = fn(exp)
			local a = exp[1] and exp[1].v
			local b = exp[2] and exp[2].v
			local c = exp[3] and exp[3].v

			if isatoom(exp) then
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, exp.v)
			elseif immjs[f] then
				-- a = CMD(a, b)
				local cmd = immjs[f]
				cmd = cmd:gsub('X', '_X_')
				cmd = cmd:gsub('Y', '_Y_')
				cmd = cmd:gsub('Z', '_Z_')
				cmd = cmd:gsub('ARGS', function() return table.concat(map(exp, function(e) return e.v end), ', ') end)
				cmd = a and cmd:gsub('_X_', a) or cmd
				cmd = b and cmd:gsub('_Y_', b) or cmd
				cmd = c and cmd:gsub('_Z_', c) or cmd
				t[#t+1] = string.format('%s%s = %s;', tabs, naam.v, cmd)
			elseif bieb[f] then
				t[#t+1] = string.format('%s%s = %s(%s);', tabs, naam.v, f, table.concat(map(exp, function(a) return a.v end), ','))
			elseif true then -- TODO check lijst
				print(f, f.ref)
				t[#t+1] = string.format('%s%s = %s[%s];', tabs, naam.v, f, table.concat(map(exp, function(a) return a.v end), ','))
			else
				t[#t+1] = string.format(tabs .. "throw 'onbekende functie: ' + " .. f .. ";")
			end
		end
	end


	-- ;(((
	local blokken = {}
	for blok in pairs(app.punten) do
		blokken[blok.naam.v] = blok
	end

	local function flow(blok, tabs)
		blokjs(blok, tabs)
		local epi = blok.epiloog
		if fn(epi) == 'ga' and #epi == 3 then
			t[#t+1] = tabs .. 'if ('..epi[1].v..') {'
			local b = blokken[epi[2].v]
			flow(b, tabs..'  ')
			t[#t+1] = tabs .. '} else {'
			flow(blokken[epi[3].v], tabs..'  ')
			t[#t+1] = tabs .. '}'
			
			local phi = blokken[b.epiloog[1].v]
			if phi then
				flow(phi, tabs)
			end
			--flow(blokken[b.epiloog[1].v])
		elseif fn(epi) == 'ga' and #epi == 1 then
			--flow(blokken[epi[1].v], tabs..'  ')
		elseif fn(epi) == 'ret' then
			t[#t+1] = tabs..'return '..epi[1].v..';'
		elseif epi.v == 'stop' then
			-- niets
		else
			error('foute epiloog: '..combineer(epi))
		end
		--print('KLAAR')
		--t[#t+1] = 
	end

	for blok in spairs(app.punten) do
		local naam = blok.naam.v
		if blok.naam.v:sub(1,2) == 'fn' then
			t[#t+1] = 'function '..naam..'(_argA, _argB, _argC) {'
			flow(blok, '  ')
			t[#t+1] = '}'
		end
	end
	flow(app.start, '')

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
		local tussencode = controle(oplos(arch_x64(exp, types), 'app'))
		local a = naarjavascript(tussencode)
		file('a.js', a)
		os.execute('js a.js > a.out')
		local b = file('a.out'):sub(1,-2)
		assert(b == waarde, 'was '..b..' maar moest zijn '..waarde)
	end

	moetzijn("uit = 1 + 1", '2')
end
