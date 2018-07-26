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

local basis = {
	['+'] = {'->', 'getal', 'getal'},
	['-'] = {'->', 'getal', 'getal'},
	['*'] = {'->', 'getal', 'getal'},
	['/'] = {'->', 'getal', 'getal'},
	['^'] = {'->', 'getal', 'getal'},
	['_'] = {'->', 'getal', 'getal'},
	['->'] = {'->', 'iets', 'iets'},
	['sincos'] = {'->', 'getal', {'^', 'getal', '2'}},
	['sin'] = {'->', 'getal', 'getal'},
	['cos'] = {'->', 'getal', 'getal'},
	['tan'] = {'->', 'getal', 'getal'},
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
	local typen = typeer(feiten,basis)
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
	local asmeta = uitrol(stroom, typen)
	    

	return asmeta, typen
end

