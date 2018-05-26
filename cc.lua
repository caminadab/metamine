#!/usr/bin/lua
require 'util'
require 'ontleed'
require 'lisp'

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

local alle = {}
for i,v in ipairs(code) do
	local code = file(v)
	local boom = ontleed(code)
	for i,v in ipairs(boom) do
		alle[#alle+1] = v
	end
end

for k,v in ipairs(alle) do
	print(k,unlisp(v))
end
