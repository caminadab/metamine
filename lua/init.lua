require 'lua/util'
require 'lua/net'
require 'lua/text'
ops = require 'lua/ops'

function grouptotext(group)
	if #group == 0 then
		return 'none'
	end
	local res = group[#group]
	if res == nil then
		print(debug.traceback())
	end
	for i = 1, #group-1 do
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

function enchant(any, name)
	if type(any) == 'table' and any.satis then
		return any
	end
	
	local m = magic()
	m.val = any
	m.text = tostring(m.val)
	m.group = {type(any)}
	
	if type(any) == 'string' then
		m.group = {'text'}
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

function magic(name)
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
		group = 'unknown',
		name = name,
		satis = true,
	}
	if watchdog then
		triggers(m, watchdog)
	end
	
	setmetatable(m, {
		__tostring = function () return m.text end
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

function refresh()
	trigger(fresh)
end

function dbg()
	-- store
	io.write("\x1B[s")
	
	-- top right
	io.write("\x1B[1;40H")
	io.write("\x1B[B")
	for name,magic in pairs(magics) do
		if magic.name ~= "watchdog" then
			io.write("\x1B[40G\x1B[K")
			io.write(grouptotext(magic.group))
			io.write('\t'..(magic.name or '<unknown>'))
			io.write(" =\t"..magic.text)
			io.write("\x1B[B")
		end
	end
	
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	io.write("\x1B[40G\x1B[K\x1B[B")
	-- restore
	io.write("\x1B[u")
	io.write("\x1B[A")
	-- prompt
	io.write("\n\x1B[33m> \x1B[37m");
end

local gmt = {}
local g = {}

function gmt:__newindex(k,v)
	if type(v) == 'table' and v.satis then
		v.name = k
		magics[k] = v
		dbg()
	end
	g[k] = v
end

function gmt:__index(k)
	return g[k]
end

setmetatable(_G, gmt)


watchdog = magic("watchdog")
watchdog.update = dbg