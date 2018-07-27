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
	'nu',
	'\'',

	-- meta
	'.',

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

	-- tijdelijk
	'index',
}

local bi = {',', 'getal', 'getal'}
local mofn = {'->', 'getal', 'getal'}
local bifn = {'->', bi, 'getal'}
local basis = {
	['+'] = bifn,
	['-'] = bifn,
	['*'] = bifn,
	['/'] = bifn,
	['^'] = bifn,
	['_'] = bifn,
	['sincos'] = {'->', 'getal', {'^', 'getal', '2'}}, -- 'getal -> getal^2'
	['wortel'] = mofn,
	['sin'] = mofn,
	['cos'] = mofn,
	['tan'] = mofn,
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
	local typen = typeer(stroom,basis)
	local asmeta = uitrol(stroom, typen)
	local func = toJs(asmeta,typen)
	return func
end

-- vertaal = code -> stroom
function vertaal(code)
	print_typen = print_typen_bron
	local feiten = ontleed(code)
	local typen,fouten = typeer(feiten,basis)
	if fouten then return nil, fouten end

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

