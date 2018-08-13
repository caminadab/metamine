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
	'nu', 'start',
	'\'',

	-- meta
	'.', 'onbekend',

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
	
	['toets-rechts']	= {'^', 'getal', '600'},
	['toets-links']		= {'^', 'getal', '600'},
	['toets-omhoog']	= {'^', 'getal', '600'},
	['toets-omlaag']	= {'^', 'getal', '600'},
	['toets-spatie']	= {'^', 'getal', '600'},
	['toets-spatie-aan'] = 'int',
	['toets-spatie-uit'] = 'int',

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

-- vertaal = code -> stroom
function vertaal(code)
	print_typen = print_typen_bron
	local feiten = ontleed(code)
	if print_ingewanden then print(unlisp(feiten)) end
	if #feiten == 0 then
		print(color.red..'geen geldige invoer gevonden'..color.white)
		return
	end
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

