#!/usr/bin/lua
package.path = package.path .. ";../?.lua"
require 'util'
require 'lisp'
require 'func'

require 'ontleed'
require 'noem'
require 'sorteer'
require 'doe'

require 'love'
require 'js'

-- argumenten
local taal = 'nl'
local doel
local code = {}
local arch = 'amd64'
local immediate
local love
local js

local args = {...}

for i=1,#args do
	local arg = args[i]
	local vlag
	if arg:sub(1,1) == '-' then
		vlag = arg:sub(2,2)
	end
	if vlag == 'o' then
		doel = args[i+1] or doel
		i = i + 1
	elseif vlag == 't' then
		arch = string.lower(arg:sub(3))
	elseif vlag == 'J' then
		js = true
		doel = 'main.js'
	elseif vlag == 'L' then
		love = true
		doel = 'main.lua'
	elseif vlag == 'i' then
		immediate = true
	elseif vlag == 'v' then
		print_losse_waarden = true
	elseif vlag == 'l' then
		taal = string.lower(arg:sub(3,5))
		if taal == '' then taal = args[i+1] end
		if not taal then taal = 'nl' end

		if taal ~= 'nl' and taal ~= 'NL' then
			print('onherkende taal '..taal)
			return
		end
	else
		-- code
		code[#code+1] = arg
	end
end

if #code == 0 then
	print('geen invoer')
	print(
[[gebruik: vt [OPTIES...] [BESTANDEN...]
Vertaalt broncode naar applicaties.
Opties:
		-i	voer meteen uit
		-l	lokale van broncode
		-o	uitvoerbestand
		-L	compileer naar love2d
		-J	compileer naar javascript
		-v	verboos zijn
]])
	return
end

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

-- lees in
local code = map(code, file)
code = table.concat(code, '\n')
-- ontleed
local feiten = ontleed(code)
local waarden = noem(feiten)
waarden.tekst = {}
waarden.getal = {}

-- speel = bieb -> cirkels
local invoer = {}
local speel = {
	van = cat(invoer, bieb),
	naar = 'cirkel',
}

--local naar = {'uit', 'cirkels', 'schrift'}

local stroom = sorteer(waarden, speel)

if love then
	uit = tolove(stroom)
elseif js then
	uit = toJs(stroom)
elseif not immediate then
	uit = unlisp(stroom)
else
	uit = unlisp(doe(stroom))
end

-- uitvoer
print(doel)
if doel then
	file(doel, uit)
else
	print(uit)
end

--
if love and immediate then
	os.execute('love .')
end
