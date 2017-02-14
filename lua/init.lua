require 'lua/util'
require 'lua/net'
require 'lua/text'
require 'lua/fs'
require 'lua/magic2text'
require 'lua/magic'
require 'lua/group'
require 'lua/poll'

function onerror(message)
	return message .. '\n' .. debug.traceback()
end

function enchant(any)
	if type(any) == 'table' and any.satis then
		return any
	end
	
	local m = magic()
	m.val = any
	m.group = {type(any)}
	
	if type(any) == 'string' then
		m.group = {'text'}
	end
	
	if type(any) == 'nil' then
		m.group = {'nil'}
	end
	
	return m
end

function print(...)
	local args = table.pack(...)
	if #args == 0 then
		args[1] = 'nil'
	end
	for i,arg in ipairs(args) do
		io.write(tostring(arg) .. '\t')
	end
	io.write('\n')
end

