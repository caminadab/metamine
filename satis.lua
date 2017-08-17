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

local color = {
	red = '\x1B[31m',
	green = '\x1B[32m',
	yellow = '\x1B[33m',
	blue = '\x1B[34m',
	purple = '\x1B[35m',
	cyan = '\x1B[36m',
	white = '\x1B[37m',
}
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
		local v = eval(sexp)
		print(color.cyan..unparseInfix(v))
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
