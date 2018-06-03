#!/usr/bin/lua
require 'util'
require 'lisp'
require 'func'

require 'ontleed'
require 'noem'
require 'rangschik'

-- argumenten
local taal = 'nl'
local doel = 'app.lisp'
local code = {}
local arch = 'amd64'

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
	return
end

-- lees in
local code = map(code, file)
code = table.concat(code, '\n')

-- ontleed
local feiten = ontleed(code)
local waarden = noem(feiten)
local stroom = rangschik(waarden, 'fotos')

print(unlisp(stroom))

-- uitvoer
file(doel, unlisp(stroom))
