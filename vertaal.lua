#!/usr/bin/lua
package.path = package.path..';../?.lua'
require 'util'
require 'lisp'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'typeer'
require 'uitrol'

require 'js'

-- standaard
local bieb = {
	-- arit
	'^', '_',
	'*', '/', '%',
	'+', '-',

	-- multi arit
	'^=', '_=',
	'*=', '/=', '%=',
	'+=', '-=',

	-- trig
	'sin', 'cos', 'tan',
	'sincos',
	'asin', 'acos', 'atan',
	'abs',
	'som',

	-- logica
	'als',
	'ja', 'nee', 'ok',
	'en', 'of', 'noch',
	'niet',
	'=>',
	'=', '!=', '~=',
	'>', '<', '>=', '<=',

	-- types
	'getal', 'int', 'tekst', 'bit',
	'goed', 'fout',
	':', 'is',
	'|', '&',
	'>>', '<<',

	-- func
	'->', '@',

	-- multi
	'[]', '#', '||', '{}',
	'..', 'xx',

	-- tijd
	'nu', 'start', 'beeld',
	'\'',

	-- meta
	'.', 'onbekend', 'tijd',

	-- converteer
	'tekst', 'getal',

	-- kleur
	'kleur', 'rgb',
	'rood', 'groen', 'blauw',
	'geel', 'oranje', 'roze', 'cyaan',
	'zwart', 'wit', 'grijs', 'lichtgrijs',
	'donkergroen', 'donkerrood', 'donkerblauw',
	'donkergeel', 'bruin', 'paars', 'magenta',

	-- toetsenbord
	'toets-links', 'toets-rechts', 'toets-omhoog', 'toets-omlaag',
	'toets-w', 'toets-s', 'toets-d', 'toets-a',

	'toets-spatie-aan', 'toets-spatie-uit',

	-- tijdelijk
	'index',
}

local bi = {',', 'getal', 'getal'}
local mofn = {'->', 'getal', 'getal'}
local bifn = {'->', bi, 'getal'}
local vglfn = {'->', bi, 'bit'}
local basis = {
	['+'] = bifn,
	['-'] = bifn,
	['*'] = bifn,
	['/'] = bifn,
	['^'] = bifn,
	['_'] = bifn,
	['>'] = vglfn,
	['<'] = vglfn,
	['='] = vglfn,
	[':='] = vglfn,
	['>='] = vglfn,
	['<='] = vglfn,
	['[]'] = {'->', {'...'}, {'^', 'iets', 'int'}},
	['{}'] = {'->', {'...'}, {'{}', 'iets', }},
	['=>'] = {'->', 'iets', 'iets'},
	['->'] = {'->', {',', 'iets', 'iets'}, {'->', 'iets', 'iets'}},
	['sincos'] = {'->', 'getal', {'^', 'getal', '2'}}, -- 'getal -> getal^2'
	['wortel'] = mofn,
	['sin'] = mofn,
	['cos'] = mofn,
	['tan'] = mofn,
	['som'] = {'->', {'^', 'getal', 'int'}, 'getal'},
	['tau'] = 'getal',
	['start'] = 'moment',
	['nu'] = 'int',
	['..'] = {'->', bifn, {'^', 'getal', 'int'}},
	['var'] = {'->', {'{}', {'->', 'moment', 'getal'}}, 'getal'},
	
	['toets-rechts']	= {'^', 'getal', '600'},
	['toets-links']		= {'^', 'getal', '600'},
	['toets-omhoog']	= {'^', 'getal', '600'},
	['toets-omlaag']	= {'^', 'getal', '600'},
	['toets-spatie']	= {'^', 'getal', '600'},
	['toets-spatie-aan'] = 'moment',
	['toets-spatie-uit'] = 'moment',

	-- impl
	[':='] = {'->', {'iets', 'iets'}, 'ok'},
	['+='] = {'->', {'iets', 'iets'}, 'ok'},
	
	-- hack
	['start'] = 'getal',
	['beeld'] = 'getal',
}

-- code in lisp formaat
function vertaalJs(lispcode)
	-- ontleed
	local feiten = lisp(lispcode)
	local waarden = noem(feiten)

	-- speel = bieb -> cirkels
	local invoer = {}
	local speel = {
		van = cat(invoer, bieb),
		naar = 'cirkel',
	}

	local stroom = sorteer(waarden, speel)
	local typen,fouten = typeer(stroom,basis)
	if fouten then
		print('ERROR')
	end
	local asmeta = uitrol(stroom, typen)
	local func = toJs(asmeta,typen)
	return func
end

function suikervrij(feiten)
	local r = {}
	for i,feit in ipairs(feiten) do
		if feit[1] == ':=' then
			local a,b = feit[2],feit[3]
			r[i] = {'=', a, {'=>', 'start', b}}
		elseif feit[1] == '+=' then
			--		a += 1
			-- =>	a = (beeld => a' + 1 / 60)
			local a,b = feit[2],feit[3]
			local ao = {"'", a}
			local an = {'+', ao, {'/', b, '60'}}
			r[i] = {'=', a, {'=>', 'beeld', an}}
		else
			r[i] = feit
		end
	end
	return r
end

--[[
	a = (T < 5 => 2)
	a = (T > 5 => 3)
]]

--[[
vertaal = code -> stroom
	ontleed: code -> feiten
	typeer: feiten => (tak -> type)
	noem: feiten => (naam -> exp)
	sorteer: namen -> stroom

	typeer stroom
	uitrol: stroom -> makkelijke-stroom
]]
function vertaal(code)
	print_typen = print_typen_bron
	local feiten = ontleed(code)

	-- syntax
	if print_ingewanden then
		print('# Ontleed')
		print(unlisp(feiten))
		print()
	end

	-- stroef doen
	if #feiten == 0 then
		print(color.red..'geen geldige invoer gevonden'..color.white)
		return
	end

	local typen,fouten = typeer(feiten,basis)
	if fouten then return nil, fouten end

	-- syn suiker
	local feiten = suikervrij(feiten)

	if print_suikervrij then
		print('# Suikervrij')
		print(unlisp(feiten))
		print()
	end

	-- aggregeer verspreide waarden
	local feiten = verzamel(feiten)

	-- isoleer allen
	local waarden = noem(feiten)

	-- speel = bieb -> cirkels
	local invoer = {}
	local speel = {
		van = cat(invoer, bieb),
		naar = 'cirkel',
	}

	local stroom = sorteer(waarden, speel)

	-- frisse avondbries
	print_typen = print_typen_stroom
	local typen = typeer(stroom,basis)

	-- breid uit
	local stroom = uitrol(stroom, typen)

	return stroom, typen
end

