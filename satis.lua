#!/usr/bin/lua
require 'sexp'
require 'sas'
require 'eval'
require 'util'

dbg = require 'debugger'

local args = {...}
local files = {}
local flags = {}

for i,arg in ipairs(args) do
	if string.sub(arg,1,1) == '-' then
		flags[arg] = true
	else
		table.insert(files, arg)
	end
end

if not flags['-c'] then
	for k,v in pairs(color) do
		color[k] = ''
	end
end

print(color.green..'satis versie 0.1.0, '..os.date()..color.white)

function shell(txt)
	if txt:match('^%s*$') then
		return
	end
	if txt == 'ls' then
		os.execute('ls --color')
		return
	end
	local ok, sexp = pcall(parse, txt)
	if not ok then
		print(color.red..sexp)
	elseif sexp then
		local ok,v = pcall(eval,sexp)
		if ok then
			print(color.cyan..unparseInfix(v))
		else
			print(color.red..v..color.white)
		end
		--print(color.purple)
		--[[for i,h in ipairs(hist) do
			print(unparse(h))
		end]]
		--print(color.white)
	end
end

-- eval file
if #files > 0 then
	local txt = file((files[1]))
	shell(txt)
	return
end

-- interactive mode
while true do
	io.write(color.yellow..'$ '..color.white)
	local line = io.read()
	if not line then
		break
	end
	shell(line)
end
