#!/usr/bin/lua
require 'util'
require 'lisp'
require 'func'

require 'ontleed'
require 'deduceer'

-- argumenten
local taal = 'nl'
local doel = 'app.lisp'
local code = {}

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
	elseif vlag == 'l' then
		taal = string.lower(arg:sub(2,4))
		if taal == '' then taal = args[i+1] end
		if not taal then taal = 'nl' end
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
local feiten = deduceer(feiten)

-- uitvoer
file(doel, unlisp(feiten))
