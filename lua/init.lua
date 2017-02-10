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

read2magic = {}
write2magic = {}
isserver = {}
write2data = {}
cid2accept = {}

function onaccept(id, cid)
	local server = read2magic[id]
	cid2accept[cid] = server
	server:accept(cid)
	trigger(server)
end

function onread(id, data)
	local client = read2magic[id]
	client:read(data)
	trigger(client)
end

function onwrite(id, written)
	local client = write2magic[id]
	client:write(written)
	write2magic[id] = nil
	write2data[id] = nil
	trigger(client)
end

function read(id, magic)
	read2magic[id] = magic
	print("READ", sas.read(id))
end

function write(id, magic, data)
	write2magic[id] = magic
	write2data[id] = data
	print("WRITE", sas.write(id))
end

function onclose(id)
	local server = cid2accept[id]
	if server then
		server:close(id)
	end
	cid2accept[id] = nil
	read2magic[id] = nil
	write2magic[id] = nil
	write2data[id] = nil
	isserver[id] = nil
	do return end
end

function accept(id, magic)
	read2magic[id] = magic
	isserver[id] = true
end

