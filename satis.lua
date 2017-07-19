#!/usr/bin/lua
require 'sexp'
require 'eval'
require 'util'

local red = '\x1B[31m'
local green = '\x1B[32m'
local yellow = '\x1B[33m'
local blue = '\x1B[34m'
local purple = '\x1B[35m'
local cyan = '\x1B[36m'
local white = '\x1B[37m'

print(green..'satis versie 0.1.0'..white)

function shell(txt)
	local ok, sexp = pcall(parse, txt)
	if not ok then
		print(red..sexp)
	else
		print(cyan..unparse(eval(sexp)))
	end
end

-- eval file
if ... then
	local files = ...
	local txt = file((files))
	shell(txt)
	return
end

-- interactive mode
while true do
	io.write(yellow..'<= '..white)
	local line = io.read()
	if not line then
		break
	end
	shell(line)
end
