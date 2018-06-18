#!/usr/bin/lua
require 'util'
require 'lisp'
require 'func'

require 'ontleed'
require 'noem'
require 'rangschik'
require 'doe'

-- argumenten
local taal = 'nl'
local doel
local code = {}
local arch = 'amd64'
local immediate = false

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
	elseif vlag == 'i' then
		immediate = true
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
[[gebruik: vt [-i] [-o uitvoer] bestanden...
		-i	voer  meteen uit
		-l	lokale
]])
	return
end

-- lees in
local code = map(code, file)
code = table.concat(code, '\n')

-- ontleed
local feiten = ontleed(code)
local waarden = noem(feiten)
waarden.tekst = {}
waarden.getal = {}
local stroom = rangschik(waarden, 'uit')
local uit 

if not immediate then
	uit = unlisp(stroom)
else
	uit = unlisp(doe(stroom))
end

-- uitvoer
if doel then
	file(doel, unlisp(stroom))
else
	print(uit)
end

