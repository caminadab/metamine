require 'lua/util'
require 'lua/net'
require 'lua/text'
require 'lua/fs'
require 'lua/magic2text'
require 'lua/magic'
require 'lua/group'

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

read2magic, write2magic, accept2magic = {}, {}, {}
write2data = {}

function accept(id, magic)
	read2magic[id] = magic
	accept2magic[id] = true
	return "accept("..id..")"
end

function read(id, magic)
	read2magic[id] = magic
	return "read("..id..")"
end

function write(id, magic, data)
	write2magic[id] = magic
	write2data[id] = data
end

function close(id, magic)
	read2magic[id] = nil
	write2magic[id] = nil
	accept2magic[id] = nil
end

