require 'lua/util'
require 'lua/net'
require 'lua/text'
require 'lua/fs'
ops = require 'lua/ops'

function onerror(message)
	return message .. '\n' .. debug.traceback()
end

function grouptotext(group)
	if #group == 0 then
		return 'none'
	end
	local res = group[#group]
	if res == nil then
		print(debug.traceback())
	end
	for i = #group-1, 1, -1 do
		-- list
		if group[i] == 'list' then
			res = '[' .. res .. ']'
			
		-- set
		elseif group[i] == 'set' then
			res = '(' .. res .. ')'
			
		-- dict
		else
			res = '{'..group[i]..'->'..res..'}'
		end
	end
	return res
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
	
	if type(any) == 'number' and any % 1 == 0 then
		m.group = {'int'}
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

magics = {}
watches = {}

local watches, fresh

function liststring(tt)
	local res = {'['}
	for i,v in ipairs(tt) do
		table.insert(res, tostring(v):sub(1,10))
		if i ~= #tt then
			table.insert(res, ' ')
		end
	end
	table.insert(res, ']')
	return table.concat(res)
end

function dictstring(tt)
	-- regular dict
	local res = {'{'}
	for k,v in pairs(tt) do
		table.insert(res, tostring(k):sub(1,4))
		table.insert(res, '=')
		if type(v) == 'string' then
			table.insert(res, string.format('%q', v:sub(-4)))
		else
			table.insert(res, tostring(v):sub(1,10))
		end
		if next(tt,k) then
			table.insert(res, ' ')
		end
	end
	table.insert(res, '}')
	return table.concat(res)
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

function encode(text)
	return string.format('%q', text:sub(-5)):gsub('\\\n', '\\n')
end

function copy(group)
	local copy = {}
	for i=1,#group do
		copy[i] = group[i]
	end
	return copy
end

function equals(a, b)
	if #a ~= #b then
		return false
	end
	
	for i=1,#a do
		if a[i] ~= b[i] then
			return false
		end
	end
	
	return true
end

--[[
[list text] -> [text]
[socket list text] -> [socket text]
]]
function indexed(parent, key)
	local child = magic()
	child.name = parent.name .. '[' .. key.. ']'
	child.val = {}
	
	-- {id->[text]} wordt {id->text}
	if #parent.group < 2 then
		error('not a group')
	end
	child.group = copy(parent.group)
	table.remove(child.group, #child.group-1)
	
	function child:update()
		child.val = nil
		for index,val in all(parent) do
			-- filtered group
			if index[#index] == key then
				local alt = copy(index)
				table.remove(alt, #alt)
				table.insert(alt, 1, 'val')
				deepset(child, alt, val)
			end
		end
	end
	
	triggers(parent, child)
	
	return child
end

function magic()
	local m = {
		-- lists of others
		triggers = {
			-- no initial triggers
		},
		events = { 
			-- check
		},
		update = function () return end,
		val = nil,
		group = {'unknown'},
		name = '<unknown>',
		satis = true,
	}
	
	setmetatable(m, {
		__tostring = function () return grouptotext(m.group) end,
		__index = function (t, v)
			if type(v) ~= 'string' then
				return indexed(m, v)
			end
		end,
	})
	
	return m
end

function trigger(magic)
	if magic.update then
		magic:update()
	end
	
	for kid,b in pairs(magic.events) do
		trigger(kid)
	end
end

function triggers(a, b)
	a.events[b] = true
	b.triggers[a] = true
	trigger(a)
end
